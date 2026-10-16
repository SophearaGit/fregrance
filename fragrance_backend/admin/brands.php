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

<?php $logoPreview = admin_image_src($form['image']); ?>
<form method="post" enctype="multipart/form-data" class="card brand-form" <?= $editing ? 'action="brands.php?edit=' . (int) $editing['id'] . '"' : '' ?>>
  <?= csrf_field() ?>
  <div class="brand-form-head">
    <div>
      <h2><?= $editing ? 'Edit "' . e($editing['name']) . '"' : 'Add a brand' ?></h2>
      <p class="muted small">Give it a name and a logo. The logo shows on the Houses tab in the app.</p>
    </div>
    <?php if ($editing): ?><a class="btn small" href="brands.php">Cancel editing</a><?php endif; ?>
  </div>

  <div class="brand-form-body">
    <!-- Logo: click or drop a file, or paste a link -->
    <label class="logo-drop <?= $logoPreview !== '' ? 'has-image' : '' ?>" for="logo" data-drop>
      <img src="<?= e($logoPreview !== '' ? $logoPreview : 'assets/no-image.svg') ?>" alt="" data-logo-preview referrerpolicy="no-referrer">
      <span class="logo-drop-hint">
        <strong>Drop a logo here</strong>
        <span>or click to choose a file</span>
      </span>
      <input type="file" id="logo" name="logo" accept="image/jpeg,image/png,image/webp,image/gif">
    </label>

    <div class="brand-form-fields">
      <div>
        <label for="name">Brand name</label>
        <input type="text" id="name" name="name" value="<?= e($form['name']) ?>" maxlength="120" required
               placeholder="e.g. Maison Francis Kurkdjian" autocomplete="off">
      </div>
      <div>
        <label for="image">Logo link <span class="muted small">(optional)</span></label>
        <input type="text" id="image" name="image" value="<?= e($form['image']) ?>" placeholder="https://example.com/logo.png"
               autocomplete="off">
        <div class="hint">Paste a link to a logo, or use the box on the left to upload one. An upload wins over a link.</div>
      </div>

      <div class="brand-chip-preview">
        <span class="muted small">In the app</span>
        <span class="brand-chip">
          <img src="<?= e($logoPreview !== '' ? $logoPreview : 'assets/no-image.svg') ?>" alt="" data-logo-preview referrerpolicy="no-referrer">
          <span data-name-preview><?= e($form['name'] !== '' ? $form['name'] : 'Brand name') ?></span>
        </span>
      </div>

      <div class="form-actions">
        <button class="btn primary" type="submit"><?= $editing ? 'Save changes' : 'Add brand' ?></button>
        <button class="btn" type="button" data-clear-logo <?= $logoPreview === '' ? 'hidden' : '' ?>>Remove logo</button>
      </div>
    </div>
  </div>
</form>

<script>
(function () {
  var form = document.querySelector('.brand-form');
  if (!form) return;
  var drop = form.querySelector('[data-drop]');
  var file = form.querySelector('#logo');
  var link = form.querySelector('#image');
  var name = form.querySelector('#name');
  var previews = form.querySelectorAll('[data-logo-preview]');
  var clear = form.querySelector('[data-clear-logo]');
  var EMPTY = 'assets/no-image.svg';

  function show(src) {
    previews.forEach(function (img) { img.src = src || EMPTY; });
    drop.classList.toggle('has-image', !!src);
    clear.hidden = !src;
  }
  file.addEventListener('change', function () {
    if (file.files && file.files[0]) show(URL.createObjectURL(file.files[0]));
  });
  link.addEventListener('input', function () {
    if (!(file.files && file.files[0])) show(/^https?:\/\//i.test(link.value.trim()) ? link.value.trim() : '');
  });
  name.addEventListener('input', function () {
    form.querySelector('[data-name-preview]').textContent = name.value.trim() || 'Brand name';
  });
  clear.addEventListener('click', function () { file.value = ''; link.value = ''; show(''); });

  ['dragenter', 'dragover'].forEach(function (type) {
    drop.addEventListener(type, function (e) { e.preventDefault(); drop.classList.add('dragging'); });
  });
  ['dragleave', 'drop'].forEach(function (type) {
    drop.addEventListener(type, function (e) { e.preventDefault(); drop.classList.remove('dragging'); });
  });
  drop.addEventListener('drop', function (e) {
    if (e.dataTransfer && e.dataTransfer.files.length) {
      file.files = e.dataTransfer.files;
      file.dispatchEvent(new Event('change'));
    }
  });
})();
</script>

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
