<?php
/**
 * GET live.php  A short fingerprint of the shop data, asked for every few seconds by
 * the admin pages. When it changes (new order, payment confirmed, stock changed...),
 * the page reloads its content by itself.
 *
 * It also asks ABA PayWay about recent unpaid PayWay orders, so a payment shows as
 * "Paid" here even if the customer closed the app before it could check.
 */
declare(strict_types=1);

require __DIR__ . '/_init.php';
require APP_ROOT . '/app/api/payway.php';

if (current_admin() === null) {
    http_response_code(401);
    header('Content-Type: application/json');
    exit(json_encode(['error' => 'signed out']));
}
session_write_close(); // do not hold up other admin pages while we work

/** Check up to 5 recent pending PayWay orders, at most once every 10 seconds. */
function admin_check_pending_payway(): int
{
    if (payway_config() === null) {
        return 0;
    }
    $stamp = APP_ROOT . '/logs/payway-poll.txt';
    if (is_file($stamp) && time() - (int) filemtime($stamp) < 10) {
        return 0;
    }
    if (!is_dir(dirname($stamp))) {
        @mkdir(dirname($stamp), 0775, true);
    }
    @touch($stamp);

    payway_ensure_schema();
    $tranIds = q("SELECT payway_tran_id FROM orders
                  WHERE status = 'pending' AND payment_method = 'aba_payway' AND payway_tran_id IS NOT NULL
                    AND created_at > (NOW() - INTERVAL 2 DAY)
                  ORDER BY id DESC LIMIT 5")->fetchAll(PDO::FETCH_COLUMN);
    foreach ($tranIds as $tranId) {
        try {
            payway_sync_order((string) $tranId);
        } catch (Throwable) {
            // PayWay not reachable right now; try again on a later check.
        }
    }
    return count($tranIds);
}

$checked = admin_check_pending_payway();

$parts = [];
foreach (db()->query('CHECKSUM TABLE orders, order_items, users, wallets, products, brands') as $row) {
    $parts[] = $row['Table'] . '=' . $row['Checksum'];
}

header('Content-Type: application/json');
header('Cache-Control: no-store');
echo json_encode(['version' => md5(implode('|', $parts)), 'paywayChecked' => $checked]);
