<?php
/** Brands: list, add, edit (brands.php?edit=3) and delete. */
declare(strict_types=1);
require __DIR__ . '/_init.php';
require_admin();

$editId = isset($_GET['edit']) ? (int) $_GET['edit'] : null;
$editing = $editId ? (q('SELECT * FROM brands WHERE id = ?', [$editId])->fetch() ?: null) : null;
$form = ['name' => $editing['name'] ?? '', 'image' => $editing['image'] ?? ''];
$errors = [];

if (is_post()) {
    verify_csrf();

    if (isset($_POST['delete_id'])) {
        $id = (int) $_POST['delete_id'];
        $brand = q('SELECT name, image FROM brands WHERE id = ?', [$id])->fetch();
        $inUse = (int) q('SELECT COUNT(*) FROM products WHERE brand_id = ?', [$id])->fetchColumn();
        if ($brand && $inUse > 0) {
            flash('bad', '"' . $brand['name'] . "\" still has $inUse product" . ($inUse === 1 ? '' : 's')
                . '. Move or delete them first.');
        } elseif ($brand) {
            q('DELETE FROM brands WHERE id = ?', [$id]);
            delete_unused_uploads([$brand['image']]);
            flash('ok', 'Deleted "' . $brand['name'] . '".');
        }
        redirect('brands.php');
    }

    $form['name'] = trim((string) ($_POST['name'] ?? ''));
    $form['image'] = trim((string) ($_POST['image'] ?? ''));
    $oldImage = $editing['image'] ?? null;

    if ($form['name'] === '') {
        $errors[] = 'Enter the brand name.';
    } elseif (q('SELECT 1 FROM brands WHERE name = ? AND id <> ?', [$form['name'], $editing['id'] ?? 0])->fetchColumn()) {
        $errors[] = 'A brand with that name already exists.';
    }
    $isUrl = (bool) preg_match('#^https?://\S+$#i', $form['image']);
    $isUpload = preg_match('#^uploads/[A-Za-z0-9._-]+$#', $form['image']) && is_file(APP_ROOT . '/' . $form['image']);
    if ($form['image'] !== '' && !$isUrl && !$isUpload) {
        $errors[] = 'The logo address must start with http:// or https://.';
    }

    if (!$errors && ($_FILES['logo']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE) {
        try {
            $form['image'] = store_uploaded_image($_FILES['logo']);   // an uploaded logo replaces the address
        } catch (RuntimeException $error) {
            $errors[] = $error->getMessage();
        }
    }

    if (!$errors) {
        $image = $form['image'] === '' ? null : $form['image'];
        if ($editing) {
            q('UPDATE brands SET name = ?, image = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
              [$form['name'], $image, $editing['id']]);
            flash('ok', 'Saved "' . $form['name'] . '".');
        } else {
            q('INSERT INTO brands (name, image) VALUES (?, ?)', [$form['name'], $image]);
            flash('ok', 'Added "' . $form['name'] . '".');
        }
        if ($oldImage !== $image) {
            delete_unused_uploads([$oldImage]);
        }
        redirect('brands.php');
    }
}

$brands = db()->query(
    'SELECT b.*, (SELECT COUNT(*) FROM products p WHERE p.brand_id = b.id) AS product_count
       FROM brands b ORDER BY b.name'
)->fetchAll();

admin_header('Brands', 'brands');
?>
<div class="page-head">
  <div><h1>Brands</h1>
    <div class="muted">A brand appears in the app once it has at least one visible product.</div></div>
</div>

<?php if ($errors): ?>
  <div class="flash bad"><?= e(implode(' ', $errors)) ?></div>
<?php endif; ?>

<form method="post" enctype="multipart/form-data" class="card" <?= $editing ? 'action="brands.php?edit=' . (int) $editing['id'] . '"' : '' ?>>
  <h2><?= $editing ? 'Edit "' . e($editing['name']) . '"' : 'Add a brand' ?></h2>
  <?= csrf_field() ?>
  <div class="grid">
    <div class="col-4"><label for="name">Name</label>
      <input type="text" id="name" name="name" value="<?= e($form['name']) ?>" maxlength="120" required></div>
    <div class="col-4"><label for="image">Logo address</label>
      <input type="text" id="image" name="image" value="<?= e($form['image']) ?>" placeholder="https://example.com/logo.png"></div>
    <div class="col-4"><label for="logo">Or upload a logo</label>
      <input type="file" id="logo" name="logo" accept="image/jpeg,image/png,image/webp,image/gif"></div>
  </div>
  <div class="form-actions" style="margin-top:14px">
    <button class="btn primary" type="submit"><?= $editing ? 'Save changes' : 'Add brand' ?></button>
    <?php if ($editing): ?><a href="brands.php">Cancel</a><?php endif; ?>
  </div>
</form>

<div class="card flush">
  <?php if (!$brands): ?>
    <div class="empty">No brands yet.</div>
  <?php else: ?>
  <div class="table-wrap"><table>
    <thead><tr><th></th><th>Brand</th><th class="num">Products</th><th></th></tr></thead>
    <tbody>
    <?php foreach ($brands as $b): ?>
      <tr>
        <td><?php if ($b['image']): ?><img class="thumb logo" src="<?= e(admin_image_src($b['image'])) ?>" alt="" loading="lazy" referrerpolicy="no-referrer"><?php else: ?><span class="thumb"></span><?php endif; ?></td>
        <td><?= e($b['name']) ?></td>
        <td class="num"><a href="products.php?brand=<?= (int) $b['id'] ?>"><?= (int) $b['product_count'] ?></a></td>
        <td class="actions">
          <a class="btn small" href="brands.php?edit=<?= (int) $b['id'] ?>">Edit</a>
          <form method="post" data-confirm="Delete the brand &quot;<?= e($b['name']) ?>&quot;?">
            <?= csrf_field() ?>
            <input type="hidden" name="delete_id" value="<?= (int) $b['id'] ?>">
            <button class="btn small danger" type="submit">Delete</button>
          </form>
        </td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table></div>
  <?php endif; ?>
</div>
<?php admin_footer();
