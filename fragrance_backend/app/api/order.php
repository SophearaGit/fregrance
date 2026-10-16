<?php
/**
 * /order endpoints: place an order (paid from the wallet), list orders, confirm receipt.
 */
declare(strict_types=1);

/** Orders in the JSON shape of the old API, each with its items. */
function orders_json(array $orders): array
{
    if ($orders === []) {
        return [];
    }
    $in = implode(',', array_map(fn ($o) => (int) $o['id'], $orders));
    $items = [];
    foreach (db()->query("SELECT * FROM order_items WHERE order_id IN ($in) ORDER BY id") as $item) {
        $items[(int) $item['order_id']][] = [
            'productId' => $item['product_id'] === null ? null : (string) $item['product_id'],
            'name'      => $item['name'],
            'price'     => json_number($item['price']),
            'quantity'  => (int) $item['quantity'],
        ];
    }

    return array_map(function (array $o) use ($items): array {
        $json = [
            'userId'        => (string) $o['user_id'],
            'currency'      => $o['currency'],
            'status'        => $o['status'],
            'items'         => $items[(int) $o['id']] ?? [],
            'paymentMethod' => $o['payment_method'],
            'totalAmount'   => json_number($o['total_amount']),
        ];
        if ($o['delivery_detail'] !== null) {
            $json['deliveryDetail'] = $o['delivery_detail'];
        }
        $json['createdAt'] = iso_date($o['created_at']);
        $json['updatedAt'] = iso_date($o['updated_at']);
        $json['id'] = (string) $o['id'];
        return $json;
    }, $orders);
}

/** The signed-in customer's id, or a 401 reply when the account no longer exists. */
function order_user_id(): int
{
    $auth = require_auth('user');
    $userId = (int) $auth['id'];
    if (!q('SELECT 1 FROM users WHERE id = ?', [$userId])->fetchColumn()) {
        json_response(401, ['message' => 'Unauthorized. User not found.']);
    }
    return $userId;
}

/**
 * POST /order  { items: [{ productId, quantity }], paymentMethod: "wallet", deliveryDetail? }
 *
 * Checks stock, charges the wallet, lowers the stock and saves the order, all in one
 * transaction so a failure part-way leaves nothing changed. Each item is charged at the
 * product's price after its discount.
 */
function api_order_create(): void
{
    $userId = order_user_id();
    $body = json_body();
    $requested = is_array($body) && is_array($body['items'] ?? null) ? $body['items'] : [];
    $paymentMethod = is_array($body) ? ($body['paymentMethod'] ?? null) : null;
    $deliveryDetail = body_string($body, 'deliveryDetail');

    if ($requested === []) {
        json_response(400, ['message' => 'Order must contain at least 1 product.']);
    }

    $pdo = db();
    $pdo->beginTransaction();
    $fail = function (int $status, array $reply) use ($pdo): never {
        $pdo->rollBack();
        json_response($status, $reply);
    };

    try {
        $lines = [];

        foreach ($requested as $item) {
            $productId = is_array($item) ? ($item['productId'] ?? '') : '';
            $quantity = is_array($item) ? ($item['quantity'] ?? null) : null;
            $label = is_scalar($productId) ? (string) $productId : '';

            if (!is_int($quantity) || $quantity <= 0) {
                $fail(400, ['message' => "Invalid quantity for $label."]);
            }
            if (!ctype_digit($label)) {
                $fail(400, ['message' => "Invalid product ID format: $label"]);
            }

            // FOR UPDATE locks the row so two orders cannot take the same last item.
            $product = q('SELECT id, name, price, discount, stock, status FROM products WHERE id = ? FOR UPDATE',
                         [(int) $label])->fetch();
            if (!$product) {
                $fail(404, ['message' => "Product $label not found."]);
            }
            if ($product['status'] === 'inactive') {
                $fail(400, ['message' => "\"{$product['name']}\" is not available."]);
            }
            // The same product listed twice counts as one line with the quantities added up.
            $id = (int) $product['id'];
            $quantity += $lines[$id]['quantity'] ?? 0;
            if ((int) $product['stock'] < $quantity) {
                $fail(400, ['message' => "Not enough stock for \"{$product['name']}\". Available: {$product['stock']}."]);
            }

            $price = round((float) $product['price'] * (1 - (float) $product['discount'] / 100), 2);
            $lines[$id] = ['id' => $id, 'name' => $product['name'], 'price' => $price, 'quantity' => $quantity];
        }

        $total = 0.0;
        foreach ($lines as $line) {
            $total += $line['price'] * $line['quantity'];
        }
        $total = round($total, 2);

        switch ($paymentMethod) {
            case 'wallet':
                $wallet = q('SELECT id, balance FROM wallets WHERE user_id = ? FOR UPDATE', [$userId])->fetch();
                if (!$wallet) {
                    $fail(404, ['message' => 'Wallet not found.']);
                }
                if ((float) $wallet['balance'] < $total) {
                    $fail(400, [
                        'message' => 'Insufficient wallet balance.',
                        'data'    => ['balance' => json_number($wallet['balance']), 'totalAmount' => json_number($total)],
                    ]);
                }
                q('UPDATE wallets SET balance = balance - ? WHERE id = ?', [$total, $wallet['id']]);
                break;
            case 'credit_card':
            case 'paypal':
            case 'bank_transfer':
                $fail(400, ['message' => 'Payment method is not supported yet.']);
            default:
                $shown = is_scalar($paymentMethod) ? (string) $paymentMethod : '';
                $fail(400, ['message' => "Payment method \"$shown\" is not supported."]);
        }

        q('INSERT INTO orders (user_id, currency, status, payment_method, total_amount, delivery_detail)
           VALUES (?, ?, ?, ?, ?, ?)',
          [$userId, 'USD', 'paid', 'wallet', $total, $deliveryDetail === '' ? null : $deliveryDetail]);
        $orderId = (int) $pdo->lastInsertId();

        foreach ($lines as $line) {
            q('INSERT INTO order_items (order_id, product_id, name, price, quantity) VALUES (?, ?, ?, ?, ?)',
              [$orderId, $line['id'], $line['name'], $line['price'], $line['quantity']]);
            q("UPDATE products
                  SET stock = stock - ?, sales_count = sales_count + ?,
                      status = IF(stock = 0, 'out_of_stock', status)
                WHERE id = ?",
              [$line['quantity'], $line['quantity'], $line['id']]);
        }

        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $error;
    }

    $order = q('SELECT * FROM orders WHERE id = ?', [$orderId])->fetchAll();
    json_response(201, ['message' => 'Order successful.', 'data' => orders_json($order)[0]]);
}

/** GET /order/processing : orders the customer has not confirmed as received yet. */
function api_order_processing(): void
{
    $userId = order_user_id();
    $orders = q("SELECT * FROM orders WHERE user_id = ? AND status <> 'received' ORDER BY id", [$userId])->fetchAll();

    json_response(200, [
        'message' => $orders ? 'Processing orders retrieved successfully.' : 'No processing orders.',
        'data'    => orders_json($orders),
    ]);
}

/** GET /order/history : orders the customer has received. */
function api_order_history(): void
{
    $userId = order_user_id();
    $orders = q("SELECT * FROM orders WHERE user_id = ? AND status = 'received' ORDER BY id", [$userId])->fetchAll();

    json_response(200, [
        'message' => $orders ? 'Order history retrieved successfully.' : 'No order history.',
        'data'    => orders_json($orders),
    ]);
}

/** POST /order/{orderId}/received : the customer confirms the order arrived. */
function api_order_received(string $orderId): void
{
    $auth = require_auth('user');
    if (!ctype_digit($orderId)) {
        json_response(400, ['message' => 'Invalid order ID format.']);
    }
    $userId = (int) $auth['id'];
    if (!q('SELECT 1 FROM users WHERE id = ?', [$userId])->fetchColumn()) {
        json_response(401, ['message' => 'Unauthorized. User not found.']);
    }

    $order = q('SELECT * FROM orders WHERE id = ?', [(int) $orderId])->fetch();
    if (!$order) {
        json_response(404, ['message' => 'Order not found.']);
    }
    if ((int) $order['user_id'] !== $userId) {
        json_response(403, ['message' => 'Access denied.']);
    }
    if ($order['status'] === 'received') {
        json_response(400, ['message' => 'Order already received.']);
    }

    q("UPDATE orders SET status = 'received' WHERE id = ?", [$order['id']]);
    $updated = q('SELECT * FROM orders WHERE id = ?', [$order['id']])->fetchAll();

    json_response(200, ['message' => 'Order received successfully.', 'data' => orders_json($updated)[0]]);
}

/** GET /order : all of the customer's orders, newest first (for "My orders"). */
function api_order_list(): void
{
    $userId = order_user_id();
    $orders = q('SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT 100', [$userId])->fetchAll();
    json_response(200, ['message' => 'Orders retrieved.', 'data' => orders_json($orders)]);
}
