<?php
/**
 * Reading and saving products. Used by both the API and the admin site.
 */
declare(strict_types=1);

/** product_attributes.type  =>  [group, key] in the JSON the app expects. */
const ATTRIBUTE_MAP = [
    'mood'        => [null, 'moods'],
    'occasion'    => [null, 'occasions'],
    'tag'         => [null, 'tags'],
    'note_top'    => ['fragranceNotes', 'top'],
    'note_middle' => ['fragranceNotes', 'middle'],
    'note_base'   => ['fragranceNotes', 'base'],
    'ingredient'  => ['productInfo', 'ingredients'],
    'how_to_use'  => ['productInfo', 'howToUse'],
    'warning'     => ['productInfo', 'warnings'],
];

const PRODUCT_STATUSES = ['active', 'inactive', 'out_of_stock'];
const PRODUCT_GENDERS  = ['men', 'women', 'unisex'];

/** Base SELECT for products joined with their brand. */
function product_select(): string
{
    return 'SELECT p.*, b.name AS brand_name, b.image AS brand_image
            FROM products p JOIN brands b ON b.id = p.brand_id';
}

/** A number as int when it is whole (120), otherwise as float (4.7), like the old API did. */
function json_number(mixed $value): int|float
{
    $float = (float) $value;
    return $float == (int) $float ? (int) $float : $float;
}

/**
 * Turn product rows into the exact JSON shape the Flutter app reads.
 * Loads the images and list values of all given products with two queries.
 */
function hydrate_products(array $rows): array
{
    if ($rows === []) {
        return [];
    }
    $ids = array_map(fn ($r) => (int) $r['id'], $rows);
    $in = implode(',', $ids);

    $images = [];
    foreach (db()->query("SELECT product_id, url FROM product_images
                          WHERE product_id IN ($in) ORDER BY sort_order, id") as $img) {
        $images[(int) $img['product_id']][] = public_image_url($img['url']);
    }

    $attributes = [];
    foreach (db()->query("SELECT product_id, type, value FROM product_attributes
                          WHERE product_id IN ($in) ORDER BY sort_order, id") as $attr) {
        $attributes[(int) $attr['product_id']][$attr['type']][] = $attr['value'];
    }

    $result = [];
    foreach ($rows as $r) {
        $id = (int) $r['id'];
        $list = fn (string $type): array => $attributes[$id][$type] ?? [];
        $result[] = [
            'name'              => $r['name'],
            'brand'             => $r['brand_name'],
            'brandImage'        => public_image_url($r['brand_image']),
            'description'       => $r['description'],
            'status'            => $r['status'],
            'size'              => $r['size'],
            'images'            => $images[$id] ?? [],
            'defaultImageIndex' => $r['default_image_index'] === null ? null : (int) $r['default_image_index'],
            'price'             => json_number($r['price']),
            'discount'          => json_number($r['discount']),
            'currency'          => $r['currency'],
            'stock'             => (int) $r['stock'],
            'salesCount'        => (int) $r['sales_count'],
            'rating'            => json_number($r['rating']),
            'tags'              => $list('tag'),
            'moods'             => $list('mood'),
            'occasions'         => $list('occasion'),
            'fragrance'         => [
                'concentration'   => $r['concentration'],
                'gender'          => $r['gender'],
                'fragranceFamily' => $r['fragrance_family'],
                'releaseYear'     => $r['release_year'] === null ? null : (int) $r['release_year'],
            ],
            'fragranceNotes'    => [
                'top'    => $list('note_top'),
                'middle' => $list('note_middle'),
                'base'   => $list('note_base'),
            ],
            'productInfo'       => [
                'ingredients' => $list('ingredient'),
                'howToUse'    => $list('how_to_use'),
                'warnings'    => $list('warning'),
            ],
            'createdAt'         => iso_date($r['created_at']),
            'updatedAt'         => iso_date($r['updated_at']),
            'id'                => (string) $id,
        ];
    }
    return $result;
}

/** One product in API shape, or null. */
function find_product(int $id): ?array
{
    $row = q(product_select() . ' WHERE p.id = ?', [$id])->fetch();
    return $row ? hydrate_products([$row])[0] : null;
}

/** The raw list values of one product, keyed by attribute type (for the admin form). */
function product_attribute_lists(int $productId): array
{
    $lists = array_fill_keys(array_keys(ATTRIBUTE_MAP), []);
    foreach (q('SELECT type, value FROM product_attributes WHERE product_id = ? ORDER BY sort_order, id',
               [$productId]) as $row) {
        $lists[$row['type']][] = $row['value'];
    }
    return $lists;
}

/** The stored image values of one product, in order (for the admin form). */
function product_image_values(int $productId): array
{
    return q('SELECT url FROM product_images WHERE product_id = ? ORDER BY sort_order, id', [$productId])
        ->fetchAll(PDO::FETCH_COLUMN);
}

/**
 * Create or update a product with its images and lists, in one transaction.
 *
 * $data keys: brand_id, name, description, status, size, default_image_index, price, discount,
 * currency, stock, sales_count, rating, concentration, gender, fragrance_family, release_year,
 * images (array of strings), attributes (type => array of strings).
 * Returns the product id.
 */
function save_product(?int $id, array $data): int
{
    $pdo = db();
    $columns = ['brand_id', 'name', 'description', 'status', 'size', 'default_image_index', 'price',
                'discount', 'currency', 'stock', 'sales_count', 'rating', 'concentration', 'gender',
                'fragrance_family', 'release_year'];
    $values = array_map(fn ($c) => $data[$c] ?? null, $columns);

    $pdo->beginTransaction();
    try {
        if ($id === null) {
            $sql = 'INSERT INTO products (' . implode(', ', $columns) . ') VALUES ('
                 . implode(', ', array_fill(0, count($columns), '?')) . ')';
            q($sql, $values);
            $id = (int) $pdo->lastInsertId();
        } else {
            $sql = 'UPDATE products SET ' . implode(', ', array_map(fn ($c) => "$c = ?", $columns))
                 . ', updated_at = CURRENT_TIMESTAMP WHERE id = ?';
            q($sql, [...$values, $id]);
        }

        q('DELETE FROM product_images WHERE product_id = ?', [$id]);
        foreach (array_values($data['images'] ?? []) as $order => $url) {
            q('INSERT INTO product_images (product_id, url, sort_order) VALUES (?, ?, ?)', [$id, $url, $order]);
        }

        q('DELETE FROM product_attributes WHERE product_id = ?', [$id]);
        foreach ($data['attributes'] ?? [] as $type => $list) {
            if (!isset(ATTRIBUTE_MAP[$type])) {
                continue;
            }
            foreach (array_values($list) as $order => $value) {
                q('INSERT INTO product_attributes (product_id, type, value, sort_order) VALUES (?, ?, ?, ?)',
                  [$id, $type, $value, $order]);
            }
        }
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }
    return $id;
}

/** Delete uploaded image files that no product or brand refers to any more. */
function delete_unused_uploads(array $storedValues): void
{
    foreach ($storedValues as $stored) {
        if (!is_string($stored) || !str_starts_with($stored, 'uploads/')) {
            continue;
        }
        $used = (int) q('SELECT (SELECT COUNT(*) FROM product_images WHERE url = ?)
                              + (SELECT COUNT(*) FROM brands WHERE image = ?)', [$stored, $stored])->fetchColumn();
        $file = UPLOAD_DIR . '/' . basename($stored);
        if ($used === 0 && is_file($file)) {
            @unlink($file);
        }
    }
}

/** Largest image upload allowed, in MB: 5, or less if this PHP's upload_max_filesize is smaller. */
function upload_limit_mb(): float
{
    $ini = trim((string) ini_get('upload_max_filesize'));
    $bytes = (float) $ini * match (strtoupper(substr($ini, -1))) {
        'G' => 1024 ** 3, 'M' => 1024 ** 2, 'K' => 1024, default => 1,
    };
    return $bytes > 0 ? round(min(5, $bytes / 1024 ** 2), 1) : 5;
}

/**
 * Save an uploaded image into uploads/ and return its stored value ("uploads/<file>").
 * Throws RuntimeException with a readable message when the file is not acceptable.
 */
function store_uploaded_image(array $file): string
{
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        throw new RuntimeException('The image "' . ($file['name'] ?? '') . '" could not be uploaded. It may be larger than '
            . upload_limit_mb() . ' MB.');
    }
    if ($file['size'] > 5 * 1024 * 1024) {
        throw new RuntimeException('The image "' . $file['name'] . '" is larger than 5 MB.');
    }
    $info = @getimagesize($file['tmp_name']);
    $extensions = [IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png', IMAGETYPE_WEBP => 'webp', IMAGETYPE_GIF => 'gif'];
    if ($info === false || !isset($extensions[$info[2]])) {
        throw new RuntimeException('"' . $file['name'] . '" is not a JPG, PNG, WebP or GIF image.');
    }
    if (!is_dir(UPLOAD_DIR) && !mkdir(UPLOAD_DIR, 0775, true)) {
        throw new RuntimeException('The uploads folder could not be created.');
    }
    $name = bin2hex(random_bytes(12)) . '.' . $extensions[$info[2]];
    if (!move_uploaded_file($file['tmp_name'], UPLOAD_DIR . '/' . $name)) {
        throw new RuntimeException('The image "' . $file['name'] . '" could not be saved to the uploads folder.');
    }
    return 'uploads/' . $name;
}
