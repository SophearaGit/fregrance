<?php
/** Product list with search, filters and delete. */
declare(strict_types=1);
require __DIR__ . '/_init.php';
require_admin();

if (is_post()) {
    verify_csrf();
    $id = (int) ($_POST['delete_id'] ?? 0);
    $product = q('SELECT name FROM products WHERE id = ?', [$id])->fetch();
    if ($product) {
        $images = product_image_values($id);
        q('DELETE FROM products WHERE id = ?', [$id]);   // images and lists go with it; old orders keep their lines
        delete_unused_uploads($images);
        flash('ok', 'Deleted "' . $product['name'] . '".');
    }
    redirect('products.php?' . http_build_query(array_filter([
        'q' => $_POST['q'] ?? '', 'brand' => $_POST['brand'] ?? '', 'status' => $_POST['status'] ?? '',
    ])));
}

$search = trim((string) ($_GET['q'] ?? ''));
$brandId = (int) ($_GET['brand'] ?? 0);
$status = (string) ($_GET['status'] ?? '');
$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = 15;

$where = ['1 = 1'];
$params = [];
if ($search !== '') {
    $where[] = '(p.name LIKE ? OR b.name LIKE ?)';
    $like = '%' . like_escape($search) . '%';
    array_push($params, $like, $like);
}
if ($brandId > 0) {
    $where[] = 'p.brand_id = ?';
    $params[] = $brandId;
}
if (in_array($status, PRODUCT_STATUSES, true)) {
    $where[] = 'p.status = ?';
    $params[] = $status;
}
$whereSql = implode(' AND ', $where);

$total = (int) q("SELECT COUNT(*) FROM products p JOIN brands b ON b.id = p.brand_id WHERE $whereSql", $params)->fetchColumn();
$pages = max(1, (int) ceil($total / $perPage));
$page = min($page, $pages);
$offset = ($page - 1) * $perPage;

$products = q(
    "SELECT p.id, p.name, p.price, p.discount, p.currency, p.stock, p.sales_count, p.status, p.size, b.name AS brand,
            (SELECT url FROM product_images pi WHERE pi.product_id = p.id
              ORDER BY (pi.sort_order = COALESCE(p.default_image_index, 0)) DESC, pi.sort_order LIMIT 1) AS image
       FROM products p JOIN brands b ON b.id = p.brand_id
      WHERE $whereSql ORDER BY p.id DESC LIMIT $perPage OFFSET $offset",
    $params
)->fetchAll();

$brands = db()->query('SELECT id, name FROM brands ORDER BY name')->fetchAll();
$filters = array_filter(['q' => $search, 'brand' => $brandId ?: '', 'status' => $status]);

admin_header('Products', 'products');
?>
<div class="page-head">
  <div><h1>Products</h1><div class="muted"><?= $total ?> product<?= $total === 1 ? '' : 's' ?></div></div>
  <div class="actions"><a class="btn primary" href="product_form.php">Add product</a></div>
</div>

<form method="get" class="toolbar">
  <input type="search" name="q" value="<?= e($search) ?>" placeholder="Search name or brand">
  <select name="brand">
    <option value="">All brands</option>
    <?php foreach ($brands as $b): ?>
      <option value="<?= (int) $b['id'] ?>" <?= $brandId === (int) $b['id'] ? 'selected' : '' ?>><?= e($b['name']) ?></option>
    <?php endforeach; ?>
  </select>
  <select name="status">
    <option value="">Any status</option>
    <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>Active</option>
    <option value="out_of_stock" <?= $status === 'out_of_stock' ? 'selected' : '' ?>>Out of stock</option>
    <option value="inactive" <?= $status === 'inactive' ? 'selected' : '' ?>>Hidden</option>
  </select>
  <button class="btn" type="submit">Filter</button>
  <?php if ($filters): ?><a href="products.php">Clear</a><?php endif; ?>
</form>

<div class="card flush">
  <?php if (!$products): ?>
    <div class="empty">No products match.</div>
  <?php else: ?>
  <div class="table-wrap"><table>
    <thead><tr><th></th><th>Product</th><th>Brand</th><th class="num">Price</th><th class="num">Discount</th>
      <th class="num">Stock</th><th class="num">Sold</th><th>Status</th><th></th></tr></thead>
    <tbody>
    <?php foreach ($products as $p): ?>
      <tr>
        <td><?php if ($p['image']): ?><img class="thumb" src="<?= e(admin_image_src($p['image'])) ?>" alt="" loading="lazy" referrerpolicy="no-referrer"><?php else: ?><span class="thumb"></span><?php endif; ?></td>
        <td><a href="product_form.php?id=<?= (int) $p['id'] ?>"><?= e($p['name']) ?></a>
          <?php if ($p['size']): ?><div class="muted small"><?= e($p['size']) ?></div><?php endif; ?></td>
        <td><?= e($p['brand']) ?></td>
        <td class="num"><?= money($p['price'], $p['currency']) ?></td>
        <td class="num"><?= (float) $p['discount'] > 0 ? e(rtrim(rtrim($p['discount'], '0'), '.')) . '%' : '<span class="muted">none</span>' ?></td>
        <td class="num"><?= (int) $p['stock'] ?></td>
        <td class="num"><?= (int) $p['sales_count'] ?></td>
        <td><?= $p['status'] === 'inactive' ? '<span class="badge">Hidden</span>' : status_badge($p['status']) ?></td>
        <td class="actions">
          <a class="btn small" href="product_form.php?id=<?= (int) $p['id'] ?>">Edit</a>
          <form method="post" data-confirm="Delete &quot;<?= e($p['name']) ?>&quot;? This cannot be undone.">
            <?= csrf_field() ?>
            <input type="hidden" name="delete_id" value="<?= (int) $p['id'] ?>">
            <input type="hidden" name="q" value="<?= e($search) ?>">
            <input type="hidden" name="brand" value="<?= $brandId ?: '' ?>">
            <input type="hidden" name="status" value="<?= e($status) ?>">
            <button class="btn small danger" type="submit">Delete</button>
          </form>
        </td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table></div>
  <?= pager($page, $pages, $filters) ?>
  <?php endif; ?>
</div>
<?php admin_footer();
