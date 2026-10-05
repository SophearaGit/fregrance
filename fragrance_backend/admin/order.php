<?php
/** One order: its items, and a form to move it to another status. */
declare(strict_types=1);
require __DIR__ . '/_init.php';
require_admin();

const ORDER_STATUSES = ['pending', 'paid', 'processing', 'shipping', 'delivered', 'received', 'cancelled', 'failed'];

$id = (int) ($_GET['id'] ?? 0);
$load = fn () => q(
    'SELECT o.*, u.fullname, u.email FROM orders o JOIN users u ON u.id = o.user_id WHERE o.id = ?', [$id]
)->fetch();
$order = $load();
if (!$order) {
    flash('bad', 'That order no longer exists.');
    redirect('orders.php');
}
$isClosed = in_array($order['status'], ['cancelled', 'failed'], true);

if (is_post()) {
    verify_csrf();
    $new = (string) ($_POST['status'] ?? '');

    if ($isClosed) {
        flash('bad', 'A cancelled or failed order cannot be changed.');
    } elseif (!in_array($new, ORDER_STATUSES, true) || $new === $order['status']) {
        flash('bad', 'Choose a different status.');
    } else {
        $pdo = db();
        $pdo->beginTransaction();
        try {
            q('UPDATE orders SET status = ? WHERE id = ?', [$new, $id]);

            // Cancelling (or failing) an order gives the money and the stock back.
            if (in_array($new, ['cancelled', 'failed'], true)) {
                if ($order['payment_method'] === 'wallet') {
                    q('UPDATE wallets SET balance = balance + ? WHERE user_id = ?', [$order['total_amount'], $order['user_id']]);
                }
                foreach (q('SELECT product_id, quantity FROM order_items WHERE order_id = ? AND product_id IS NOT NULL', [$id]) as $item) {
                    q("UPDATE products
                          SET stock = stock + ?, sales_count = GREATEST(sales_count - ?, 0),
                              status = IF(status = 'out_of_stock', 'active', status)
                        WHERE id = ?", [$item['quantity'], $item['quantity'], $item['product_id']]);
                }
            }
            $pdo->commit();
            flash('ok', in_array($new, ['cancelled', 'failed'], true)
                ? 'Order marked as ' . $new . '. The customer was refunded and the stock was put back.'
                : 'Order marked as ' . $new . '.');
        } catch (Throwable $error) {
            $pdo->rollBack();
            throw $error;
        }
    }
    redirect('order.php?id=' . $id);
}

$items = q(
    'SELECT i.*, (SELECT url FROM product_images pi WHERE pi.product_id = i.product_id ORDER BY pi.sort_order LIMIT 1) AS image
       FROM order_items i WHERE i.order_id = ? ORDER BY i.id', [$id]
)->fetchAll();

admin_header('Order #' . $id, 'orders');
?>
<div class="page-head">
  <div><h1>Order #<?= $id ?> <?= status_badge($order['status']) ?></h1>
    <div class="muted">Placed <?= show_date($order['created_at']) ?> · last changed <?= show_date($order['updated_at']) ?></div></div>
  <div class="actions"><a class="btn" href="orders.php">Back to orders</a></div>
</div>

<div class="grid">
  <div class="col-8">
    <div class="card flush">
      <div class="table-wrap"><table>
        <thead><tr><th></th><th>Item</th><th class="num">Price</th><th class="num">Qty</th><th class="num">Subtotal</th></tr></thead>
        <tbody>
        <?php foreach ($items as $item): ?>
          <tr>
            <td><?php if ($item['image']): ?><img class="thumb" src="<?= e(admin_image_src($item['image'])) ?>" alt="" loading="lazy" referrerpolicy="no-referrer"><?php else: ?><span class="thumb"></span><?php endif; ?></td>
            <td><?= e($item['name']) ?><?php if ($item['product_id'] === null): ?><div class="muted small">Product since deleted</div><?php endif; ?></td>
            <td class="num"><?= money($item['price'], $order['currency']) ?></td>
            <td class="num"><?= (int) $item['quantity'] ?></td>
            <td class="num"><?= money((float) $item['price'] * (int) $item['quantity'], $order['currency']) ?></td>
          </tr>
        <?php endforeach; ?>
          <tr><td colspan="4" class="right"><strong>Total</strong></td>
            <td class="num"><strong><?= money($order['total_amount'], $order['currency']) ?></strong></td></tr>
        </tbody>
      </table></div>
    </div>
  </div>

  <div class="col-4">
    <div class="card">
      <h2>Customer</h2>
      <p><?= e($order['fullname']) ?><br><span class="muted"><?= e($order['email']) ?></span></p>
      <p class="small"><span class="muted">Payment:</span> <?= e(ucfirst(str_replace('_', ' ', $order['payment_method']))) ?></p>
      <?php if ($order['delivery_detail']): ?>
        <p class="small"><span class="muted">Delivery note:</span> <?= e($order['delivery_detail']) ?></p>
      <?php endif; ?>
    </div>

    <div class="card">
      <h2>Change status</h2>
      <?php if ($isClosed): ?>
        <p class="muted small">This order is <?= e($order['status']) ?> and can no longer be changed.</p>
      <?php else: ?>
      <form method="post" action="order.php?id=<?= $id ?>">
        <?= csrf_field() ?>
        <select name="status" style="margin-bottom:10px">
          <?php foreach (ORDER_STATUSES as $s): if ($s === $order['status']) continue; ?>
            <option value="<?= $s ?>"><?= ucfirst($s) ?></option>
          <?php endforeach; ?>
        </select>
        <button class="btn primary" type="submit">Update status</button>
        <p class="hint">Cancelled or failed refunds the wallet and puts the stock back.
          "Received" is normally set by the customer in the app.</p>
      </form>
      <?php endif; ?>
    </div>
  </div>
</div>
<?php admin_footer();
