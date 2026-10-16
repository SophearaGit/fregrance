<?php
/** Order list with a status filter. */
declare(strict_types=1);
require __DIR__ . '/_init.php';
require_admin();

const ORDER_STATUSES = ['pending', 'paid', 'processing', 'shipping', 'delivered', 'received', 'cancelled', 'failed'];

$status = (string) ($_GET['status'] ?? '');
$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = 20;

$where = '1 = 1';
$params = [];
if (in_array($status, ORDER_STATUSES, true)) {
    $where = 'o.status = ?';
    $params[] = $status;
}

$total = (int) q("SELECT COUNT(*) FROM orders o WHERE $where", $params)->fetchColumn();
$pages = max(1, (int) ceil($total / $perPage));
$page = min($page, $pages);
$offset = ($page - 1) * $perPage;

$orders = q(
    "SELECT o.*, u.fullname, u.email,
            (SELECT COALESCE(SUM(quantity), 0) FROM order_items i WHERE i.order_id = o.id) AS item_count
       FROM orders o JOIN users u ON u.id = o.user_id
      WHERE $where ORDER BY o.id DESC LIMIT $perPage OFFSET $offset",
    $params
)->fetchAll();

admin_header('Orders', 'orders');
?>
<div class="page-head">
  <div><h1>Orders</h1><div class="muted"><?= $total ?> order<?= $total === 1 ? '' : 's' ?></div></div>
</div>

<form method="get" class="toolbar">
  <select name="status" onchange="this.form.submit()">
    <option value="">Any status</option>
    <?php foreach (ORDER_STATUSES as $s): ?>
      <option value="<?= $s ?>" <?= $status === $s ? 'selected' : '' ?>><?= ucfirst($s) ?></option>
    <?php endforeach; ?>
  </select>
  <noscript><button class="btn" type="submit">Filter</button></noscript>
</form>

<div class="card flush">
  <?php if (!$orders): ?>
    <div class="empty">No orders<?= $status !== '' ? ' with this status' : ' yet' ?>.</div>
  <?php else: ?>
  <div class="table-wrap"><table>
    <thead><tr><th>Order</th><th>Customer</th><th>Placed</th><th class="num">Items</th><th>Payment</th><th>Status</th><th class="num">Total</th></tr></thead>
    <tbody>
    <?php foreach ($orders as $o): ?>
      <tr>
        <td><a href="order.php?id=<?= (int) $o['id'] ?>">#<?= (int) $o['id'] ?></a></td>
        <td><?= e($o['fullname']) ?><div class="muted small"><?= e($o['email']) ?></div></td>
        <td class="nowrap"><?= show_date($o['created_at']) ?></td>
        <td class="num"><?= (int) $o['item_count'] ?></td>
        <td><?= e(payment_label($o['payment_method'])) ?></td>
        <td><?= status_badge($o['status']) ?></td>
        <td class="num"><?= money($o['total_amount'], $o['currency']) ?></td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table></div>
  <?= pager($page, $pages, array_filter(['status' => $status])) ?>
  <?php endif; ?>
</div>
<?php admin_footer();
