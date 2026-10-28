<?php
/** Customer reviews: read them, search, and remove ones that break the rules. */
declare(strict_types=1);
require __DIR__ . '/_init.php';
require_admin();
ensure_social_schema();

if (is_post()) {
    verify_csrf();
    $id = (int) ($_POST['delete_id'] ?? 0);
    $review = q('SELECT r.product_id, u.fullname FROM product_reviews r JOIN users u ON u.id = r.user_id WHERE r.id = ?',
                [$id])->fetch();
    if ($review) {
        q('DELETE FROM product_reviews WHERE id = ?', [$id]);
        refresh_product_rating((int) $review['product_id']);
        flash('ok', 'Removed the review by ' . $review['fullname'] . '.');
    }
    redirect('reviews.php' . ($_SERVER['QUERY_STRING'] ? '?' . $_SERVER['QUERY_STRING'] : ''));
}

$search = trim((string) ($_GET['q'] ?? ''));
$stars = (int) ($_GET['stars'] ?? 0);
$where = ['1 = 1'];
$params = [];
if ($search !== '') {
    $where[] = '(p.name LIKE ? OR u.fullname LIKE ? OR r.comment LIKE ?)';
    $like = '%' . like_escape($search) . '%';
    array_push($params, $like, $like, $like);
}
if ($stars >= 1 && $stars <= 5) {
    $where[] = 'r.rating = ?';
    $params[] = $stars;
}
$whereSql = implode(' AND ', $where);

$page = max(1, (int) ($_GET['page'] ?? 1));
$perPage = 25;
$total = (int) q("SELECT COUNT(*) FROM product_reviews r JOIN products p ON p.id = r.product_id
                  JOIN users u ON u.id = r.user_id WHERE $whereSql", $params)->fetchColumn();
$pages = max(1, (int) ceil($total / $perPage));
$offset = ($page - 1) * $perPage;
$reviews = q(
    "SELECT r.*, p.name AS product_name, u.fullname, u.email,
            (SELECT url FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.sort_order LIMIT 1) AS image
       FROM product_reviews r JOIN products p ON p.id = r.product_id JOIN users u ON u.id = r.user_id
      WHERE $whereSql ORDER BY r.updated_at DESC, r.id DESC LIMIT $perPage OFFSET $offset",
    $params
)->fetchAll();
$average = q('SELECT AVG(rating) FROM product_reviews')->fetchColumn();

function stars(int $n): string
{
    return '<span class="stars" title="' . $n . ' of 5">' . str_repeat('★', $n) . '<span class="off">'
         . str_repeat('★', 5 - $n) . '</span></span>';
}

admin_header('Reviews', 'reviews');
?>
<div class="page-head">
  <div><h1>Reviews</h1>
    <div class="muted"><?= $total ?> review<?= $total === 1 ? '' : 's' ?>
      <?php if ($average !== null): ?> · average <?= number_format((float) $average, 1) ?> ★<?php endif; ?>
      · customers can review products they have bought.</div></div>
</div>

<form method="get" class="toolbar">
  <input type="search" name="q" value="<?= e($search) ?>" placeholder="Search product, customer or words">
  <select name="stars">
    <option value="">Any rating</option>
    <?php for ($s = 5; $s >= 1; $s--): ?>
      <option value="<?= $s ?>" <?= $stars === $s ? 'selected' : '' ?>><?= $s ?> star<?= $s === 1 ? '' : 's' ?></option>
    <?php endfor; ?>
  </select>
  <button class="btn" type="submit">Filter</button>
</form>

<div class="card flush">
  <?php if (!$reviews): ?>
    <div class="empty">No reviews<?= $search !== '' || $stars ? ' match' : ' yet' ?>.</div>
  <?php else: ?>
  <div class="table-wrap"><table>
    <thead><tr><th></th><th>Product</th><th>Customer</th><th>Rating</th><th>Review</th><th>Date</th><th></th></tr></thead>
    <tbody>
    <?php foreach ($reviews as $r): ?>
      <tr>
        <td><?php if ($r['image']): ?><img class="thumb" src="<?= e(admin_image_src($r['image'])) ?>" alt="" loading="lazy" referrerpolicy="no-referrer"><?php else: ?><span class="thumb"></span><?php endif; ?></td>
        <td><a href="product_form.php?id=<?= (int) $r['product_id'] ?>"><?= e($r['product_name']) ?></a></td>
        <td><?= e($r['fullname']) ?><div class="muted small"><?= e($r['email']) ?></div></td>
        <td class="nowrap"><?= stars((int) $r['rating']) ?></td>
        <td style="max-width:360px"><?= $r['comment'] !== '' ? nl2br(e($r['comment'])) : '<span class="muted">No comment</span>' ?></td>
        <td class="nowrap"><?= show_date($r['updated_at']) ?></td>
        <td class="actions">
          <form method="post" data-confirm="Remove this review by <?= e($r['fullname']) ?>?">
            <?= csrf_field() ?>
            <input type="hidden" name="delete_id" value="<?= (int) $r['id'] ?>">
            <button class="btn small danger" type="submit">Remove</button>
          </form>
        </td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table></div>
  <?= pager($page, $pages, array_filter(['q' => $search, 'stars' => $stars ?: ''])) ?>
  <?php endif; ?>
</div>
<?php admin_footer();
