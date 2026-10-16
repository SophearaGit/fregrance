<?php
/**
 * ABA PayWay checkout.
 *
 * 1. POST /order/payway          The app sends the cart. We save a "pending" order
 *                                (stock is not taken yet) and reply with a checkout link.
 * 2. GET  /payway/checkout/{id}  The app opens that link in a web view. The page sends
 *                                a signed purchase request to PayWay, which shows its
 *                                payment screen (card, ABA Pay, KHQR).
 * 3. GET  /payway/return         PayWay sends the customer here when they finish or cancel.
 *                                The app sees this address and closes the web view.
 * 4. POST /order/payway/check    The app asks us to confirm. We ask PayWay
 *                                (check-transaction) and only then mark the order paid
 *                                and take the stock.
 * POST /payway/callback          PayWay's own notice (only reaches us when the backend is
 *                                online); it runs the same check.
 *
 * Hashes follow PayWay's rules: base64(HMAC-SHA512(fields joined in a fixed order, api_key)).
 */
declare(strict_types=1);

/** PayWay settings from payway-config.php, or null when not filled in. */
function payway_config(): ?array
{
    $file = APP_ROOT . '/payway-config.php';
    $config = is_file($file) ? require $file : null;
    if (!is_array($config) || ($config['merchant_id'] ?? '') === '' || ($config['api_key'] ?? '') === '') {
        return null;
    }
    $config['api_url'] = rtrim((string) ($config['api_url'] ?? 'https://checkout-sandbox.payway.com.kh'), '/');
    return $config;
}

function payway_hash(string $data, string $apiKey): string
{
    return base64_encode(hash_hmac('sha512', $data, $apiKey, true));
}

/** PayWay wants the request time in UTC as YYYYMMDDHHmmss. */
function payway_req_time(): string
{
    return gmdate('YmdHis');
}

/** Older databases were made before PayWay existed: add what it needs, once. */
function payway_ensure_schema(): void
{
    static $done = false;
    if ($done) {
        return;
    }
    $hasColumn = (bool) q("SELECT 1 FROM information_schema.COLUMNS
                           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'orders' AND COLUMN_NAME = 'payway_tran_id'")
        ->fetchColumn();
    if (!$hasColumn) {
        db()->exec("ALTER TABLE orders
            MODIFY payment_method ENUM('wallet','credit_card','paypal','bank_transfer','aba_payway') NOT NULL,
            ADD COLUMN payway_tran_id VARCHAR(20) NULL AFTER delivery_detail,
            ADD UNIQUE KEY uq_orders_payway_tran (payway_tran_id)");
    }
    $done = true;
}

/** Short secret that lets only our app open the checkout page of an order. */
function payway_page_key(string $tranId): string
{
    return substr(hash_hmac('sha256', 'payway-page:' . $tranId, (string) (app_config()['jwt_secret'] ?? '')), 0, 32);
}

/** POST /order/payway  { items: [{productId, quantity}], deliveryDetail? } */
function api_order_payway_create(): void
{
    $userId = order_user_id();
    if (payway_config() === null) {
        json_response(503, ['message' => 'ABA PayWay is not set up yet. Fill in fragrance_backend/payway-config.php.']);
    }
    payway_ensure_schema();

    $body = json_body();
    $requested = is_array($body) && is_array($body['items'] ?? null) ? $body['items'] : [];
    $deliveryDetail = body_string($body, 'deliveryDetail');
    if ($requested === []) {
        json_response(400, ['message' => 'Order must contain at least 1 product.']);
    }

    // Check every product and work out the price, like the wallet checkout does.
    $lines = [];
    foreach ($requested as $item) {
        $label = is_array($item) && is_scalar($item['productId'] ?? null) ? (string) $item['productId'] : '';
        $quantity = is_array($item) ? ($item['quantity'] ?? null) : null;
        if (!is_int($quantity) || $quantity <= 0 || !ctype_digit($label)) {
            json_response(400, ['message' => 'The cart has an item that is not valid.']);
        }
        $product = q('SELECT id, name, price, discount, stock, status FROM products WHERE id = ?', [(int) $label])->fetch();
        if (!$product) {
            json_response(404, ['message' => "Product $label not found."]);
        }
        if ($product['status'] === 'inactive') {
            json_response(400, ['message' => "\"{$product['name']}\" is not available."]);
        }
        $id = (int) $product['id'];
        $quantity += $lines[$id]['quantity'] ?? 0;
        if ((int) $product['stock'] < $quantity) {
            json_response(400, ['message' => "Not enough stock for \"{$product['name']}\". Available: {$product['stock']}."]);
        }
        $price = round((float) $product['price'] * (1 - (float) $product['discount'] / 100), 2);
        $lines[$id] = ['id' => $id, 'name' => $product['name'], 'price' => $price, 'quantity' => $quantity];
    }
    $total = 0.0;
    foreach ($lines as $line) {
        $total += $line['price'] * $line['quantity'];
    }
    $total = round($total, 2);

    $pdo = db();
    $pdo->beginTransaction();
    try {
        q("INSERT INTO orders (user_id, currency, status, payment_method, total_amount, delivery_detail)
           VALUES (?, 'USD', 'pending', 'aba_payway', ?, ?)",
          [$userId, $total, $deliveryDetail === '' ? null : $deliveryDetail]);
        $orderId = (int) $pdo->lastInsertId();
        // Unique per attempt and at most 20 characters, as PayWay requires.
        $tranId = 'FR' . $orderId . 'T' . strtoupper(base_convert((string) time(), 10, 36));
        q('UPDATE orders SET payway_tran_id = ? WHERE id = ?', [$tranId, $orderId]);
        foreach ($lines as $line) {
            q('INSERT INTO order_items (order_id, product_id, name, price, quantity) VALUES (?, ?, ?, ?, ?)',
              [$orderId, $line['id'], $line['name'], $line['price'], $line['quantity']]);
        }
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }

    json_response(201, [
        'message' => 'Order created. Waiting for payment.',
        'data'    => [
            'orderId'     => (string) $orderId,
            'tranId'      => $tranId,
            'amount'      => json_number($total),
            'checkoutUrl' => api_base_url() . '/payway/checkout/' . $tranId . '?k=' . payway_page_key($tranId),
            'returnUrl'   => api_base_url() . '/payway/return',
        ],
    ]);
}

/** GET /payway/checkout/{tranId}?k=...  A page that sends the signed purchase to PayWay. */
function api_payway_checkout_page(string $tranId): void
{
    header('Content-Type: text/html; charset=utf-8');
    $config = payway_config();
    $key = (string) ($_GET['k'] ?? '');
    if ($config === null || !hash_equals(payway_page_key($tranId), $key)) {
        http_response_code(403);
        exit('<p style="font-family:sans-serif;padding:24px">This payment link is not valid.</p>');
    }
    payway_ensure_schema();

    $order = q("SELECT o.*, u.fullname, u.email FROM orders o JOIN users u ON u.id = o.user_id
                WHERE o.payway_tran_id = ?", [$tranId])->fetch();
    if (!$order || $order['status'] !== 'pending') {
        http_response_code(410);
        exit('<p style="font-family:sans-serif;padding:24px">This order is already ' . e((string) ($order['status'] ?? 'closed'))
            . '. You can go back to the app.</p>');
    }

    $items = [];
    foreach (q('SELECT name, price, quantity FROM order_items WHERE order_id = ? ORDER BY id', [$order['id']]) as $item) {
        $items[] = ['name' => $item['name'], 'quantity' => (int) $item['quantity'], 'price' => (float) $item['price']];
    }
    $names = preg_split('/\s+/', trim((string) $order['fullname']), 2) ?: [];
    $returnBase = api_base_url() . '/payway/return?tran=' . rawurlencode($tranId);

    // Field order matters: it is the order PayWay uses to check the hash.
    $fields = [
        'req_time'             => payway_req_time(),
        'merchant_id'          => $config['merchant_id'],
        'tran_id'              => $tranId,
        'amount'               => number_format((float) $order['total_amount'], 2, '.', ''),
        'items'                => base64_encode(json_encode($items, JSON_UNESCAPED_UNICODE)),
        'shipping'             => '',
        'firstname'            => mb_substr($names[0] ?? '', 0, 20),
        'lastname'             => mb_substr($names[1] ?? '', 0, 20),
        'email'                => (string) $order['email'],
        'phone'                => '',
        'type'                 => 'purchase',
        'payment_option'       => '',
        'return_url'           => base64_encode(api_base_url() . '/payway/callback'),
        'cancel_url'           => $returnBase . '&result=cancel',
        'continue_success_url' => $returnBase . '&result=success',
        'return_deeplink'      => '',
        'currency'             => 'USD',
        'custom_fields'        => '',
        'return_params'        => '',
        'payout'               => '',
        'lifetime'             => '',
        'additional_params'    => '',
        'google_pay_token'     => '',
        // 1 = go straight back to the app after paying, without PayWay's own success page.
        'skip_success_page'    => '1',
    ];
    $fields['hash'] = payway_hash(implode('', $fields), $config['api_key']);

    // PayWay only accepts purchases that come from a website on the merchant's
    // whitelist. The phone's web view is not one, so the backend sends the request
    // itself, from the whitelisted address in payway-config.php ('domain'), and
    // shows PayWay's payment page in the web view.
    $page = payway_post_purchase($config, array_filter($fields, fn ($value) => $value !== ''));
    echo $page;
    exit;
}

/** Send the purchase to PayWay and return its payment page, ready to show in the app. */
function payway_post_purchase(array $config, array $fields): string
{
    $curl = curl_init($config['api_url'] . '/api/payment-gateway/v1/payments/purchase');
    $headers = ['Accept: text/html,application/json'];
    $domain = rtrim((string) ($config['domain'] ?? ''), '/');
    if ($domain !== '') {
        $headers[] = 'Origin: ' . $domain;
        $headers[] = 'Referer: ' . $domain . '/';
    }
    curl_setopt_array($curl, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $fields, // an array is sent as multipart/form-data
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_TIMEOUT        => 30,
    ]);
    foreach ([(string) ini_get('curl.cainfo'), 'C:/laragon/etc/ssl/cacert.pem',
              dirname((string) ($_SERVER['DOCUMENT_ROOT'] ?? '')) . '/etc/ssl/cacert.pem'] as $ca) {
        if ($ca !== '' && is_file($ca)) {
            curl_setopt($curl, CURLOPT_CAINFO, $ca);
            break;
        }
    }
    $responseHeaders = [];
    curl_setopt($curl, CURLOPT_HEADERFUNCTION, function ($handle, string $line) use (&$responseHeaders): int {
        $parts = explode(':', $line, 2);
        if (count($parts) === 2) {
            $responseHeaders[strtolower(trim($parts[0]))] = trim($parts[1]);
        }
        return strlen($line);
    });
    $result = curl_exec($curl);
    $status = (int) curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $type = (string) curl_getinfo($curl, CURLINFO_CONTENT_TYPE);
    $error = curl_error($curl);
    curl_close($curl);

    // Keep PayWay's last reply for troubleshooting (logs/ is not committed).
    $logDir = APP_ROOT . '/logs';
    if (is_dir($logDir) || @mkdir($logDir, 0775, true)) {
        @file_put_contents($logDir . '/payway-last-purchase.txt',
            gmdate('c') . "\nHTTP $status\n" . print_r($responseHeaders, true) . "\n"
            . ($result === false ? 'curl error: ' . $error : (string) $result));
    }

    if ($result === false) {
        return payway_message_page('Could not reach ABA PayWay: ' . $error);
    }
    // PayWay may answer with a redirect to its payment page: send the web view there.
    if ($status >= 300 && $status < 400 && !empty($responseHeaders['location'])) {
        $location = $responseHeaders['location'];
        if (!preg_match('#^https?://#i', $location)) {
            $location = $config['api_url'] . '/' . ltrim($location, '/');
        }
        header('Location: ' . $location, true, 302);
        return '';
    }
    if (trim((string) $result) === '') {
        return payway_message_page("ABA PayWay sent an empty reply (HTTP $status).");
    }
    if (str_contains($type, 'json')) {
        $reply = json_decode((string) $result, true);
        $message = is_array($reply) ? (string) ($reply['status']['message'] ?? $reply['description'] ?? $result) : (string) $result;
        return payway_message_page('ABA PayWay: ' . $message);
    }

    // The page came from PayWay, so its links must keep pointing at PayWay.
    $base = '<base href="' . e($config['api_url']) . '/">';
    $html = (string) $result;
    return preg_match('/<head[^>]*>/i', $html)
        ? preg_replace('/<head[^>]*>/i', '$0' . $base, $html, 1)
        : $base . $html;
}

function payway_message_page(string $message): string
{
    return '<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1">'
         . '<p style="font-family:sans-serif;padding:24px;text-align:center">' . e($message)
         . '<br><br>Close this page and try again.</p>';
}

/** GET /payway/return?tran=..&result=success|cancel  Where PayWay sends the customer back. */
function api_payway_return(): void
{
    header('Content-Type: text/html; charset=utf-8');
    $cancelled = ($_GET['result'] ?? '') === 'cancel';
    echo '<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1">'
       . '<p style="font-family:sans-serif;padding:24px;text-align:center">'
       . ($cancelled ? 'Payment cancelled.' : 'Thank you! Checking your payment…')
       . '<br>You can go back to the app.</p>';
    exit;
}

/**
 * Ask PayWay about a transaction and update our order to match.
 * Returns 'paid', 'pending' or 'cancelled'.
 */
function payway_sync_order(string $tranId): string
{
    $config = payway_config();
    if ($config === null) {
        throw new RuntimeException('ABA PayWay is not set up.');
    }
    payway_ensure_schema();

    $order = q('SELECT id, status, total_amount FROM orders WHERE payway_tran_id = ?', [$tranId])->fetch();
    if (!$order) {
        return 'cancelled';
    }
    if ($order['status'] !== 'pending') {
        return in_array($order['status'], ['cancelled', 'failed'], true) ? 'cancelled' : 'paid';
    }

    $reqTime = payway_req_time();
    $reply = payway_post_json($config['api_url'] . '/api/payment-gateway/v1/payments/check-transaction-2', [
        'req_time'    => $reqTime,
        'merchant_id' => $config['merchant_id'],
        'tran_id'     => $tranId,
        'hash'        => payway_hash($reqTime . $config['merchant_id'] . $tranId, $config['api_key']),
    ]);

    $code = (string) ($reply['status']['code'] ?? '');
    $paymentStatus = strtoupper((string) ($reply['data']['payment_status'] ?? ''));
    if ($code !== '00') {
        // Usually "transaction not found": the customer has not paid yet.
        return 'pending';
    }

    if ($paymentStatus === 'APPROVED') {
        $paid = (float) ($reply['data']['original_amount'] ?? $reply['data']['total_amount'] ?? 0);
        if (abs($paid - (float) $order['total_amount']) > 0.01) {
            throw new RuntimeException("PayWay amount ($paid) does not match the order total ({$order['total_amount']}).");
        }
        payway_mark_paid((int) $order['id']);
        return 'paid';
    }
    if (in_array($paymentStatus, ['DECLINED', 'CANCELLED'], true)) {
        q("UPDATE orders SET status = 'cancelled' WHERE id = ? AND status = 'pending'", [$order['id']]);
        return 'cancelled';
    }
    return 'pending';
}

/** Payment confirmed: take the stock and mark the order paid (only once). */
function payway_mark_paid(int $orderId): void
{
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $status = q('SELECT status FROM orders WHERE id = ? FOR UPDATE', [$orderId])->fetchColumn();
        if ($status === 'pending') {
            foreach (q('SELECT product_id, quantity FROM order_items WHERE order_id = ? AND product_id IS NOT NULL',
                       [$orderId])->fetchAll() as $item) {
                q("UPDATE products
                      SET stock = GREATEST(stock - ?, 0), sales_count = sales_count + ?,
                          status = IF(stock = 0, 'out_of_stock', status)
                    WHERE id = ?",
                  [$item['quantity'], $item['quantity'], $item['product_id']]);
            }
            q("UPDATE orders SET status = 'paid' WHERE id = ?", [$orderId]);
        }
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }
}

/** POST a JSON body to PayWay and return the decoded reply. */
function payway_post_json(string $url, array $data): array
{
    $curl = curl_init($url);
    curl_setopt_array($curl, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json', 'Accept: application/json'],
        CURLOPT_POSTFIELDS     => json_encode($data),
        CURLOPT_TIMEOUT        => 20,
    ]);
    // Laragon's PHP may not know where the trusted certificates are; point it at Laragon's copy.
    foreach ([(string) ini_get('curl.cainfo'), 'C:/laragon/etc/ssl/cacert.pem',
              dirname((string) ($_SERVER['DOCUMENT_ROOT'] ?? '')) . '/etc/ssl/cacert.pem'] as $ca) {
        if ($ca !== '' && is_file($ca)) {
            curl_setopt($curl, CURLOPT_CAINFO, $ca);
            break;
        }
    }
    $result = curl_exec($curl);
    $error = curl_error($curl);
    curl_close($curl);
    if ($result === false) {
        throw new RuntimeException('Could not reach ABA PayWay: ' . $error);
    }
    $decoded = json_decode((string) $result, true);
    if (!is_array($decoded)) {
        throw new RuntimeException('ABA PayWay sent an unexpected reply: ' . substr((string) $result, 0, 200));
    }
    return $decoded;
}

/** POST /order/payway/check  { tranId }  The app asks whether its payment went through. */
function api_order_payway_check(): void
{
    $userId = order_user_id();
    $tranId = body_string(json_body(), 'tranId');
    payway_ensure_schema();
    $owner = q('SELECT user_id FROM orders WHERE payway_tran_id = ?', [$tranId])->fetchColumn();
    if ($tranId === '' || $owner === false || (int) $owner !== $userId) {
        json_response(404, ['message' => 'Order not found.']);
    }

    try {
        $status = payway_sync_order($tranId);
    } catch (RuntimeException $error) {
        json_response(502, ['message' => $error->getMessage()]);
    }

    $messages = [
        'paid'      => 'Payment received. Thank you!',
        'pending'   => 'The payment is not finished yet.',
        'cancelled' => 'The payment was cancelled.',
    ];
    json_response(200, ['message' => $messages[$status], 'data' => ['status' => $status, 'tranId' => $tranId]]);
}

/** POST /payway/callback  PayWay's notice after a payment (when the backend is online). */
function api_payway_callback(): void
{
    $body = json_body();
    $tranId = is_array($body) ? (string) ($body['tran_id'] ?? '') : '';
    if ($tranId === '') {
        $tranId = (string) ($_POST['tran_id'] ?? '');
    }
    if ($tranId !== '') {
        try {
            payway_sync_order($tranId); // Never trust the notice itself: ask PayWay.
        } catch (Throwable) {
            // PayWay will try again; the app also checks.
        }
    }
    json_response(200, ['message' => 'OK']);
}
