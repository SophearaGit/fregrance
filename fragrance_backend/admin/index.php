<?php
/** Dashboard: totals, recent orders and products running low. */
declare(strict_types=1);
require __DIR__ . '/_init.php';
require_admin();

$stats = db()->query(
    "SELECT (SELECT COUNT(*) FROM products) AS products,
            (SELECT COUNT(*) FROM brands) AS brands,
            (SELECT COUNT(*) FROM users WHERE role = 'user') AS customers,
            (SELECT COUNT(*) FROM orders) AS orders,
            (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE status NOT IN ('cancelled', 'failed')) AS revenue"
)->fetch();

$recentOrders = db()->query(
    "SELECT o.id, o.total_amount, o.currency, o.status, o.created_at, u.fullname
       FROM orders o JOIN users u ON u.id = o.user_id
      ORDER BY o.id DESC LIMIT 6"
)->fetchAll();

$lowStock = db()->query(
    "SELECT p.id, p.name, p.stock, b.name AS brand
       FROM products p JOIN brands b ON b.id = p.brand_id
      WHERE p.stock <= 5 AND p.status <> 'inactive'
      ORDER BY p.stock, p.name LIMIT 8"
)->fetchAll();

admin_header('Dashboard', 'dashboard');
?>
<div class="page-head">
  <div><h1>Dashboard</h1><div class="muted">An overview of the shop.</div></div>
  <div class="actions"><a class="btn primary" href="product_form.php">Add product</a></div>
</div>

<div class="stats">
  <div class="stat"><div class="label">Products</div><div class="value"><?= (int) $stats['products'] ?></div></div>
  <div class="stat"><div class="label">Brands</div><div class="value"><?= (int) $stats['brands'] ?></div></div>
  <div class="stat"><div class="label">Customers</div><div class="value"><?= (int) $stats['customers'] ?></div></div>
  <div class="stat"><div class="label">Orders</div><div class="value"><?= (int) $stats['orders'] ?></div></div>
  <div class="stat"><div class="label">Sales</div><div class="value"><?= e(number_format((float) $stats['revenue'], 2)) ?></div></div>
</div>

<div class="card flush">
  <h2>Recent orders</h2>
  <?php if (!$recentOrders): ?>
    <div class="empty">No orders yet.</div>
  <?php else: ?>
  <div class="table-wrap"><table>
    <thead><tr><th>Order</th><th>Customer</th><th>Placed</th><th>Status</th><th class="num">Total</th></tr></thead>
    <tbody>
    <?php foreach ($recentOrders as $o): ?>
      <tr>
        <td><a href="order.php?id=<?= (int) $o['id'] ?>">#<?= (int) $o['id'] ?></a></td>
        <td><?= e($o['fullname']) ?></td>
        <td class="nowrap"><?= show_date($o['created_at']) ?></td>
        <td><?= status_badge($o['status']) ?></td>
        <td class="num"><?= money($o['total_amount'], $o['currency']) ?></td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table></div>
  <?php endif; ?>
</div>

<div class="card flush">
  <h2>Low stock</h2>
  <?php if (!$lowStock): ?>
    <div class="empty">Nothing is running low.</div>
  <?php else: ?>
  <div class="table-wrap"><table>
    <thead><tr><th>Product</th><th>Brand</th><th class="num">In stock</th><th></th></tr></thead>
    <tbody>
    <?php foreach ($lowStock as $p): ?>
      <tr>
        <td><?= e($p['name']) ?></td>
        <td><?= e($p['brand']) ?></td>
        <td class="num"><?= (int) $p['stock'] ?></td>
        <td class="actions"><a class="btn small" href="product_form.php?id=<?= (int) $p['id'] ?>">Edit</a></td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table></div>
  <?php endif; ?>
</div>
<?php admin_footer();
