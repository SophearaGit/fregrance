<?php
/** Add a product, or edit one (product_form.php?id=12). */
declare(strict_types=1);
require __DIR__ . '/_init.php';
require_admin();

$id = isset($_GET['id']) ? (int) $_GET['id'] : null;
$existing = null;
if ($id !== null) {
    $existing = q('SELECT * FROM products WHERE id = ?', [$id])->fetch();
    if (!$existing) {
        flash('bad', 'That product no longer exists.');
        redirect('products.php');
    }
}

// Which form box holds which list, and whether commas separate items in it.
$listFields = [
    'mood' => ['moods', true], 'occasion' => ['occasions', true], 'tag' => ['tags', true],
    'note_top' => ['note_top', true], 'note_middle' => ['note_middle', true], 'note_base' => ['note_base', true],
    'ingredient' => ['ingredients', false], 'how_to_use' => ['how_to_use', false], 'warning' => ['warnings', false],
];

// ---- Values shown in the form ----
if ($existing) {
    $lists = product_attribute_lists($id);
    $oldImages = product_image_values($id);
    $form = [
        'name' => $existing['name'], 'brand_id' => (string) $existing['brand_id'], 'new_brand' => '',
        'description' => (string) $existing['description'], 'visible' => $existing['status'] === 'inactive' ? '0' : '1',
        'size' => (string) $existing['size'], 'price' => (string) (float) $existing['price'],
        'discount' => (string) (float) $existing['discount'], 'currency' => $existing['currency'],
        'stock' => (string) $existing['stock'], 'sales_count' => (string) $existing['sales_count'],
        'rating' => (string) (float) $existing['rating'], 'concentration' => $existing['concentration'],
        'gender' => $existing['gender'], 'fragrance_family' => $existing['fragrance_family'],
        'release_year' => (string) $existing['release_year'], 'images' => implode("\n", $oldImages),
        'main_image' => (string) (($existing['default_image_index'] ?? 0) + 1),
    ];
    foreach ($listFields as $type => [$field, $commas]) {
        $form[$field] = implode($commas ? ', ' : "\n", $lists[$type]);
    }
} else {
    $oldImages = [];
    $form = [
        'name' => '', 'brand_id' => '', 'new_brand' => '', 'description' => '', 'visible' => '1', 'size' => '',
        'price' => '', 'discount' => '0', 'currency' => 'USD', 'stock' => '0', 'sales_count' => '0', 'rating' => '0',
        'concentration' => 'Eau de Parfum', 'gender' => 'unisex', 'fragrance_family' => '', 'release_year' => '',
        'images' => '', 'main_image' => '1',
    ];
    foreach ($listFields as [$field]) {
        $form[$field] = '';
    }
}

$errors = [];

if (is_post()) {
    verify_csrf();
    foreach ($form as $key => $unused) {
        $form[$key] = trim((string) ($_POST[$key] ?? ''));
    }

    // ---- Check the typed values ----
    if ($form['name'] === '') {
        $errors[] = 'Enter the product name.';
    }
    if ($form['new_brand'] === '' && !q('SELECT 1 FROM brands WHERE id = ?', [(int) $form['brand_id']])->fetchColumn()) {
        $errors[] = 'Choose a brand, or type a new brand name.';
    }
    if (!is_numeric($form['price']) || (float) $form['price'] < 0) {
        $errors[] = 'Enter a price of 0 or more.';
    }
    if (!is_numeric($form['discount']) || (float) $form['discount'] < 0 || (float) $form['discount'] > 100) {
        $errors[] = 'The discount is a percentage from 0 to 100.';
    }
    if (!ctype_digit($form['stock'])) {
        $errors[] = 'Stock must be a whole number, 0 or more.';
    }
    if (!ctype_digit($form['sales_count'])) {
        $errors[] = 'Sold must be a whole number, 0 or more.';
    }
    if (!is_numeric($form['rating']) || (float) $form['rating'] < 0 || (float) $form['rating'] > 5) {
        $errors[] = 'The rating is a number from 0 to 5.';
    }
    if ($form['concentration'] === '') {
        $errors[] = 'Enter the concentration, for example Eau de Parfum.';
    }
    if (!in_array($form['gender'], PRODUCT_GENDERS, true)) {
        $errors[] = 'Choose who the fragrance is for.';
    }
    if ($form['fragrance_family'] === '') {
        $errors[] = 'Enter the scent family, for example Woody.';
    }
    if ($form['release_year'] !== '' && (!ctype_digit($form['release_year'])
        || (int) $form['release_year'] < 1800 || (int) $form['release_year'] > 2100)) {
        $errors[] = 'The release year should look like 2014, or be left empty.';
    }
    if ($form['currency'] === '' || strlen($form['currency']) > 8) {
        $errors[] = 'Enter a currency code such as USD.';
    }

    // Image lines: a web address, or an image uploaded earlier ("uploads/<file>").
    $images = [];
    foreach (parse_list($form['images'], false) as $line) {
        $isUrl = (bool) preg_match('#^https?://\S+$#i', $line);
        $isUpload = preg_match('#^uploads/[A-Za-z0-9._-]+$#', $line) && is_file(APP_ROOT . '/' . $line);
        if (!$isUrl && !$isUpload) {
            $errors[] = 'This image line is not a web address starting with http:// or https:// : ' . $line;
        } else {
            $images[] = $line;
        }
    }

    // ---- Save uploaded image files (only when everything else is fine) ----
    $uploaded = [];
    if (!$errors && !empty($_FILES['new_images']['name'][0])) {
        $files = $_FILES['new_images'];
        try {
            foreach (array_keys($files['name']) as $i) {
                if ($files['error'][$i] === UPLOAD_ERR_NO_FILE) {
                    continue;
                }
                $uploaded[] = store_uploaded_image([
                    'name' => $files['name'][$i], 'tmp_name' => $files['tmp_name'][$i],
                    'error' => $files['error'][$i], 'size' => $files['size'][$i],
                ]);
            }
        } catch (RuntimeException $error) {
            $errors[] = $error->getMessage();
            delete_unused_uploads($uploaded);
            $uploaded = [];
        }
    }

    if (!$errors) {
        $images = array_merge($images, $uploaded);

        // Brand: a newly typed name wins; reuse the brand if it already exists.
        if ($form['new_brand'] !== '') {
            $brandId = (int) q('SELECT id FROM brands WHERE name = ?', [$form['new_brand']])->fetchColumn();
            if ($brandId === 0) {
                q('INSERT INTO brands (name) VALUES (?)', [$form['new_brand']]);
                $brandId = (int) db()->lastInsertId();
            }
        } else {
            $brandId = (int) $form['brand_id'];
        }

        $stock = (int) $form['stock'];
        $mainIndex = ctype_digit($form['main_image']) ? (int) $form['main_image'] - 1 : 0;
        $attributes = [];
        foreach ($listFields as $type => [$field, $commas]) {
            $attributes[$type] = parse_list($form[$field], $commas);
        }

        $savedId = save_product($id, [
            'brand_id'            => $brandId,
            'name'                => $form['name'],
            'description'         => $form['description'] === '' ? null : $form['description'],
            // Hidden products are "inactive"; visible ones are active or out of stock depending on the stock.
            'status'              => $form['visible'] === '0' ? 'inactive' : ($stock > 0 ? 'active' : 'out_of_stock'),
            'size'                => $form['size'] === '' ? null : $form['size'],
            'default_image_index' => $images ? max(0, min($mainIndex, count($images) - 1)) : null,
            'price'               => round((float) $form['price'], 2),
            'discount'            => round((float) $form['discount'], 2),
            'currency'            => strtoupper($form['currency']),
            'stock'               => $stock,
            'sales_count'         => (int) $form['sales_count'],
            'rating'              => round((float) $form['rating'], 1),
            'concentration'       => $form['concentration'],
            'gender'              => $form['gender'],
            'fragrance_family'    => $form['fragrance_family'],
            'release_year'        => $form['release_year'] === '' ? null : (int) $form['release_year'],
            'images'              => $images,
            'attributes'          => $attributes,
        ]);

        delete_unused_uploads(array_diff($oldImages, $images));
        flash('ok', ($id === null ? 'Added "' : 'Saved "') . $form['name'] . '".');
        redirect('products.php');
    }
}

$brands = db()->query('SELECT id, name FROM brands ORDER BY name')->fetchAll();
$concentrations = db()->query('SELECT DISTINCT concentration FROM products ORDER BY 1')->fetchAll(PDO::FETCH_COLUMN);
$families = db()->query('SELECT DISTINCT fragrance_family FROM products ORDER BY 1')->fetchAll(PDO::FETCH_COLUMN);
$previewImages = parse_list($form['images'], false);

admin_header($existing ? 'Edit product' : 'Add product', 'products');
?>
<div class="page-head">
  <div><h1><?= $existing ? 'Edit product' : 'Add product' ?></h1>
    <?php if ($existing): ?><div class="muted">Added <?= show_date($existing['created_at']) ?> · last changed <?= show_date($existing['updated_at']) ?></div><?php endif; ?></div>
  <div class="actions"><a class="btn" href="products.php">Back to products</a></div>
</div>

<?php if ($errors): ?>
  <div class="flash bad">Please fix the following and save again:
    <ul><?php foreach ($errors as $error): ?><li><?= e($error) ?></li><?php endforeach; ?></ul></div>
<?php endif; ?>

<form method="post" enctype="multipart/form-data">
  <?= csrf_field() ?>

  <div class="card">
    <h2>Basics</h2>
    <div class="grid">
      <div class="col-8"><label for="name">Name</label>
        <input type="text" id="name" name="name" value="<?= e($form['name']) ?>" maxlength="190" required></div>
      <div class="col-4"><label for="size">Size</label>
        <input type="text" id="size" name="size" value="<?= e($form['size']) ?>" maxlength="40" placeholder="100ml"></div>

      <div class="col-6"><label for="brand_id">Brand</label>
        <select id="brand_id" name="brand_id">
          <option value="">Choose a brand</option>
          <?php foreach ($brands as $b): ?>
            <option value="<?= (int) $b['id'] ?>" <?= $form['brand_id'] === (string) $b['id'] ? 'selected' : '' ?>><?= e($b['name']) ?></option>
          <?php endforeach; ?>
        </select></div>
      <div class="col-6"><label for="new_brand">Or add a new brand</label>
        <input type="text" id="new_brand" name="new_brand" value="<?= e($form['new_brand']) ?>" maxlength="120" placeholder="New brand name">
        <div class="hint">Leave empty to use the brand chosen on the left. Add its logo later under Brands.</div></div>

      <div class="col-12"><label for="description">Description</label>
        <textarea id="description" name="description" rows="3"><?= e($form['description']) ?></textarea></div>

      <div class="col-4"><label for="visible">Show in the app</label>
        <select id="visible" name="visible">
          <option value="1" <?= $form['visible'] === '1' ? 'selected' : '' ?>>Yes</option>
          <option value="0" <?= $form['visible'] === '0' ? 'selected' : '' ?>>No, keep it hidden</option>
        </select>
        <div class="hint">A visible product with 0 stock shows as out of stock.</div></div>
    </div>
  </div>

  <div class="card">
    <h2>Price and stock</h2>
    <div class="grid">
      <div class="col-3"><label for="price">Price</label>
        <input type="number" id="price" name="price" value="<?= e($form['price']) ?>" min="0" step="0.01" required></div>
      <div class="col-3"><label for="discount">Discount %</label>
        <input type="number" id="discount" name="discount" value="<?= e($form['discount']) ?>" min="0" max="100" step="0.01"></div>
      <div class="col-3"><label for="currency">Currency</label>
        <input type="text" id="currency" name="currency" value="<?= e($form['currency']) ?>" maxlength="8"></div>
      <div class="col-3"><label for="stock">Stock</label>
        <input type="number" id="stock" name="stock" value="<?= e($form['stock']) ?>" min="0" step="1"></div>
      <div class="col-3"><label for="sales_count">Sold</label>
        <input type="number" id="sales_count" name="sales_count" value="<?= e($form['sales_count']) ?>" min="0" step="1">
        <div class="hint">Goes up by itself with each order. Drives "Popular".</div></div>
      <div class="col-3"><label for="rating">Rating</label>
        <input type="number" id="rating" name="rating" value="<?= e($form['rating']) ?>" min="0" max="5" step="0.1"></div>
    </div>
  </div>

  <div class="card">
    <h2>Fragrance</h2>
    <div class="grid">
      <div class="col-4"><label for="concentration">Concentration</label>
        <input type="text" id="concentration" name="concentration" value="<?= e($form['concentration']) ?>" list="concentrations" maxlength="80" required>
        <datalist id="concentrations"><?php foreach ($concentrations as $c): ?><option value="<?= e($c) ?>"><?php endforeach; ?></datalist></div>
      <div class="col-4"><label for="gender">For</label>
        <select id="gender" name="gender">
          <?php foreach (PRODUCT_GENDERS as $g): ?>
            <option value="<?= $g ?>" <?= $form['gender'] === $g ? 'selected' : '' ?>><?= ucfirst($g) ?></option>
          <?php endforeach; ?>
        </select></div>
      <div class="col-4"><label for="release_year">Release year</label>
        <input type="number" id="release_year" name="release_year" value="<?= e($form['release_year']) ?>" min="1800" max="2100" step="1"></div>
      <div class="col-12"><label for="fragrance_family">Scent family</label>
        <input type="text" id="fragrance_family" name="fragrance_family" value="<?= e($form['fragrance_family']) ?>" list="families" maxlength="120" required>
        <datalist id="families"><?php foreach ($families as $f): ?><option value="<?= e($f) ?>"><?php endforeach; ?></datalist></div>

      <div class="col-4"><label for="note_top">Top notes</label>
        <textarea id="note_top" name="note_top" rows="2"><?= e($form['note_top']) ?></textarea></div>
      <div class="col-4"><label for="note_middle">Middle notes</label>
        <textarea id="note_middle" name="note_middle" rows="2"><?= e($form['note_middle']) ?></textarea></div>
      <div class="col-4"><label for="note_base">Base notes</label>
        <textarea id="note_base" name="note_base" rows="2"><?= e($form['note_base']) ?></textarea></div>

      <div class="col-4"><label for="moods">Moods</label>
        <textarea id="moods" name="moods" rows="2"><?= e($form['moods']) ?></textarea></div>
      <div class="col-4"><label for="occasions">Occasions</label>
        <textarea id="occasions" name="occasions" rows="2"><?= e($form['occasions']) ?></textarea></div>
      <div class="col-4"><label for="tags">Tags</label>
        <textarea id="tags" name="tags" rows="2"><?= e($form['tags']) ?></textarea></div>
      <div class="col-12 hint">Separate the items in these six boxes with commas, for example: Lemon, Grapefruit, Mint.
        Moods, occasions, notes and scent family are what the app's Discovery screen filters by.</div>
    </div>
  </div>

  <div class="card">
    <h2>Images</h2>
    <!-- Filled in by the script below from the image list: click ✕ to remove, ★ to make it the main image. -->
    <div class="image-editor" data-image-editor></div>
    <div class="image-notice" data-image-notice hidden></div>
    <div class="photo-finder" data-photo-finder>
      <label for="photo_query">Find photos online</label>
      <div class="photo-finder-bar">
        <input type="search" id="photo_query" placeholder="e.g. Chanel No 5" autocomplete="off">
        <button class="btn" type="button" data-photo-search>Search</button>
      </div>
      <div class="photo-results" data-photo-results></div>
      <div class="photo-finder-note">
        Photos come from <a href="https://world.openbeautyfacts.org" target="_blank" rel="noopener">Open Beauty Facts</a>,
        a free open database (photos may be reused under its open licence). Click a photo to add it below, then save.
      </div>
    </div>

    <div class="grid">
      <div class="col-12"><label for="images">Image addresses, one per line</label>
        <textarea id="images" name="images" rows="4" placeholder="https://example.com/photo.png"><?= e($form['images']) ?></textarea>
        <div class="hint">Remove a line to remove that image. Change the order of the lines to change the order.</div></div>
      <div class="col-8"><label for="new_images">Upload images from this computer</label>
        <input type="file" id="new_images" name="new_images[]" accept="image/jpeg,image/png,image/webp,image/gif" multiple>
        <div class="hint">JPG, PNG, WebP or GIF, up to <?= upload_limit_mb() ?> MB each. Uploaded images are added after the ones above.</div></div>
      <div class="col-4"><label for="main_image">Main image number</label>
        <input type="number" id="main_image" name="main_image" value="<?= e($form['main_image']) ?>" min="1" step="1">
        <div class="hint">The image shown on product cards.</div></div>
    </div>
  </div>

  <div class="card">
    <h2>Product information</h2>
    <div class="grid">
      <div class="col-4"><label for="ingredients">Ingredients</label>
        <textarea id="ingredients" name="ingredients" rows="4"><?= e($form['ingredients']) ?></textarea></div>
      <div class="col-4"><label for="how_to_use">How to use</label>
        <textarea id="how_to_use" name="how_to_use" rows="4"><?= e($form['how_to_use']) ?></textarea></div>
      <div class="col-4"><label for="warnings">Warnings</label>
        <textarea id="warnings" name="warnings" rows="4"><?= e($form['warnings']) ?></textarea></div>
      <div class="col-12 hint">One item per line in these three boxes.</div>
    </div>
  </div>

  <div class="form-actions">
    <button class="btn primary" type="submit"><?= $existing ? 'Save changes' : 'Add product' ?></button>
    <a href="products.php">Cancel</a>
  </div>
</form>
<script>
(function () {
  var box = document.querySelector('[data-photo-finder]');
  if (!box) return;
  var query = box.querySelector('#photo_query');
  var button = box.querySelector('[data-photo-search]');
  var results = box.querySelector('[data-photo-results]');
  var images = document.getElementById('images');
  var timer;

  // Start from "Brand Name" of the product being edited.
  function suggested() {
    var brandSelect = document.getElementById('brand_id');
    var newBrand = document.getElementById('new_brand');
    var brand = (newBrand && newBrand.value.trim())
      || (brandSelect && brandSelect.value ? brandSelect.options[brandSelect.selectedIndex].text : '');
    var name = (document.getElementById('name') || {}).value || '';
    return (brand + ' ' + name).trim();
  }
  query.value = suggested();
  ['name', 'brand_id', 'new_brand'].forEach(function (id) {
    var el = document.getElementById(id);
    if (el) el.addEventListener('change', function () { if (!query.dataset.touched) query.value = suggested(); });
  });
  query.addEventListener('input', function () {
    query.dataset.touched = '1';
    clearTimeout(timer);
    timer = setTimeout(search, 600); // search as you type
  });
  query.addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); search(); } });
  button.addEventListener('click', search);

  function message(text) { results.innerHTML = '<div class="muted small">' + text + '</div>'; }

  function search() {
    var q = query.value.trim();
    if (q.length < 2) { message('Type a perfume name to search.'); return; }
    message('Searching…');
    fetch('photo_search.php?q=' + encodeURIComponent(q), { credentials: 'same-origin' })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (data.error) { message(data.error); return; }
        if (!data.results.length) { message('No photos found. Try just the brand, or a shorter name.'); return; }
        results.innerHTML = '';
        data.results.forEach(function (item) {
          var card = document.createElement('button');
          card.type = 'button';
          card.className = 'photo-result';
          var img = document.createElement('img');
          img.src = item.thumb; img.alt = ''; img.loading = 'lazy'; img.referrerPolicy = 'no-referrer';
          var text = document.createElement('span');
          var title = document.createElement('strong');
          title.textContent = item.name;
          text.appendChild(title);
          text.appendChild(document.createTextNode([item.brand, item.size].filter(Boolean).join(' · ')));
          card.appendChild(img); card.appendChild(text);
          if (images.value.indexOf(item.image) !== -1) card.classList.add('added');
          card.addEventListener('click', function () {
            if (images.value.indexOf(item.image) !== -1) return;
            images.value = (images.value.trim() ? images.value.trim() + '\n' : '') + item.image;
            card.classList.add('added');
          });
          results.appendChild(card);
        });
      })
      .catch(function () { message('Could not search right now. Is the internet on?'); });
  }
})();
</script>
<script>
(function () {
  var editor = document.querySelector('[data-image-editor]');
  var notice = document.querySelector('[data-image-notice]');
  var text = document.getElementById('images');
  var main = document.getElementById('main_image');
  if (!editor || !text || !main) return;
  var NO_IMAGE = 'assets/no-image.svg';
  var autoCleaned = false;
  var undo = null;

  function lines() { return text.value.split(/\r?\n/).map(function (l) { return l.trim(); }).filter(Boolean); }
  function setLines(list) { text.value = list.join('\n'); }
  function mainIndex() { return Math.max(1, parseInt(main.value, 10) || 1); }
  function src(value) { return /^https?:\/\//i.test(value) ? value : '../' + value.replace(/^\/+/, ''); }

  function remove(positions) {
    var list = lines();
    var current = mainIndex();
    var kept = list.filter(function (_, i) { return positions.indexOf(i + 1) === -1; });
    var before = positions.filter(function (n) { return n < current; }).length;
    var mainGone = positions.indexOf(current) !== -1;
    setLines(kept);
    main.value = kept.length ? (mainGone ? 1 : current - before) : 1;
    render();
  }

  var generation = 0; // only the newest drawing of the list may clean it up

  function render() {
    var mine = ++generation;
    var list = lines();
    var current = Math.min(mainIndex(), Math.max(list.length, 1));
    editor.innerHTML = '';
    if (!list.length) {
      editor.innerHTML = '<div class="image-empty"><img src="' + NO_IMAGE + '" alt=""><span>No photos yet. Find one online, paste a link or upload below.</span></div>';
      return;
    }
    var pending = list.length, broken = [];
    list.forEach(function (value, i) {
      var tile = document.createElement('figure');
      tile.className = 'image-tile' + (i + 1 === current ? ' is-main' : '');
      var img = document.createElement('img');
      img.alt = '';
      img.loading = 'eager';
      img.referrerPolicy = 'no-referrer';
      img.dataset.noFallback = '1';
      img.onload = function () { done(); };
      img.onerror = function () {
        img.onerror = null;
        img.src = NO_IMAGE;
        tile.classList.add('is-broken');
        broken.push(i + 1);
        done();
      };
      img.src = src(value);
      var star = document.createElement('button');
      star.type = 'button'; star.className = 'tile-main'; star.title = 'Make this the main image';
      star.textContent = i + 1 === current ? '★ Main' : '☆';
      star.onclick = function () { main.value = i + 1; render(); };
      var x = document.createElement('button');
      x.type = 'button'; x.className = 'tile-remove'; x.title = 'Remove this image'; x.textContent = '✕';
      x.onclick = function () { undo = { text: text.value, main: main.value }; remove([i + 1]); say('Image removed.'); };
      var caption = document.createElement('figcaption');
      caption.textContent = 'Image ' + (i + 1);
      tile.appendChild(img); tile.appendChild(star); tile.appendChild(x); tile.appendChild(caption);
      editor.appendChild(tile);
    });

    function done() {
      if (mine !== generation) return; // the list changed meanwhile
      if (--pending > 0) return;
      // Broken links next to working photos are cleaned up once, automatically.
      if (!autoCleaned && broken.length && broken.length < list.length) {
        autoCleaned = true;
        undo = { text: text.value, main: main.value };
        remove(broken.sort(function (a, b) { return a - b; }));
        say(broken.length + ' broken image' + (broken.length === 1 ? ' was' : 's were') + ' removed. Save to keep this.');
      }
    }
  }

  function say(message) {
    notice.hidden = false;
    notice.innerHTML = '';
    notice.appendChild(document.createTextNode(message + ' '));
    if (undo) {
      var b = document.createElement('button');
      b.type = 'button'; b.className = 'btn small'; b.textContent = 'Undo';
      b.onclick = function () { text.value = undo.text; main.value = undo.main; undo = null; notice.hidden = true; render(); };
      notice.appendChild(b);
    }
  }

  text.addEventListener('input', function () { clearTimeout(render.t); render.t = setTimeout(render, 400); });
  main.addEventListener('change', render);
  // Photos picked in "Find photos online" are added to the text box: show them at once.
  var results = document.querySelector('[data-photo-results]');
  if (results) results.addEventListener('click', function () { setTimeout(render, 0); });
  render();
})();
</script>
<?php admin_footer();
