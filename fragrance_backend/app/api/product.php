<?php
/**
 * /product endpoints: lists, home feed, brands, discovery filters, details.
 * Products with status "inactive" are hidden from every list.
 */
declare(strict_types=1);

const VISIBLE = "p.status <> 'inactive'";

/** SQL test: the product has a list value of one of these types matching "?" . */
function has_attribute(array $types, string $operator = '='): string
{
    $in = "'" . implode("','", $types) . "'";
    return "EXISTS (SELECT 1 FROM product_attributes a
                    WHERE a.product_id = p.id AND a.type IN ($in) AND a.value $operator ?)";
}

/** Reply with one page of products. */
function product_page_reply(string $message, array $where, array $params, string $orderBy): never
{
    [$page, $limit, $offset] = pagination_input();
    $whereSql = implode(' AND ', array_merge([VISIBLE], $where));

    $total = (int) q("SELECT COUNT(*) FROM products p JOIN brands b ON b.id = p.brand_id WHERE $whereSql", $params)
        ->fetchColumn();
    $rows = q(product_select() . " WHERE $whereSql ORDER BY $orderBy LIMIT $limit OFFSET $offset", $params)
        ->fetchAll();

    json_response(200, [
        'message'    => $message,
        'data'       => hydrate_products($rows),
        'pagination' => pagination_block($page, $limit, $total, count($rows)),
    ]);
}

/** GET /product?search=&minRating=&maxRating=&page=&limit= */
function api_product_index(): void
{
    if ((int) db()->query('SELECT COUNT(*) FROM products')->fetchColumn() === 0) {
        json_response(404, ['message' => 'Products not found.', 'data' => []]);
    }

    $where = [];
    $params = [];

    $search = query('search');
    if ($search !== null) {
        $like = '%' . like_escape($search) . '%';
        $where[] = '(p.name LIKE ? OR b.name LIKE ? OR p.concentration LIKE ? OR p.gender LIKE ?
                     OR p.fragrance_family LIKE ? OR '
                 . has_attribute(['note_top', 'note_middle', 'note_base', 'ingredient'], 'LIKE') . ')';
        array_push($params, $like, $like, $like, $like, $like, $like);
    }
    if (is_numeric($_GET['minRating'] ?? null)) {
        $where[] = 'p.rating >= ?';
        $params[] = (float) $_GET['minRating'];
    }
    if (is_numeric($_GET['maxRating'] ?? null)) {
        $where[] = 'p.rating <= ?';
        $params[] = (float) $_GET['maxRating'];
    }

    product_page_reply('Products fetched successfully.', $where, $params, 'p.id ASC');
}

/** GET /product/featured : the three highlighted products on the home screen. */
function api_product_featured(): void
{
    $one = fn (string $orderBy, int $offset = 0) =>
        q(product_select() . ' WHERE ' . VISIBLE . " ORDER BY $orderBy LIMIT 1 OFFSET $offset")->fetch() ?: null;

    $fallback = $one('p.id ASC');
    if ($fallback === null) {
        json_response(404, ['message' => 'Featured items not found.', 'data' => null]);
    }

    $newArrival = $one('p.created_at DESC, p.id DESC') ?? $fallback;      // newest
    $topSales   = $one('p.discount DESC, p.id ASC') ?? $fallback;         // biggest discount
    $trending   = $one('p.sales_count DESC, p.id ASC', 1)                 // second best seller,
               ?? $one('p.sales_count DESC, p.id ASC') ?? $fallback;      // as the old API chose

    [$newArrival, $topSales, $trending] = hydrate_products([$newArrival, $topSales, $trending]);

    json_response(200, [
        'message' => 'Featured items fetched successfully.',
        'data'    => ['newArrival' => $newArrival, 'topSales' => $topSales, 'trending' => $trending],
    ]);
}

/** GET /product/feed?tab=all|new|popular|sale|men|women|unisex&page=&limit= */
function api_product_feed(): void
{
    $tab = strtolower(query('tab') ?? 'all');
    $where = [];
    $params = [];
    $orderBy = 'p.id ASC';

    switch ($tab) {
        case 'new':
            $orderBy = 'p.created_at DESC, p.id DESC';
            break;
        case 'popular':
            $orderBy = 'p.sales_count DESC, p.id ASC';
            break;
        case 'sale':
            $where[] = 'p.discount > 0';
            break;
        case 'men':
        case 'women':
        case 'unisex':
            $where[] = 'p.gender = ?';
            $params[] = $tab;
            break;
    }

    product_page_reply("Feed for tab $tab fetched successfully.", $where, $params, $orderBy);
}

/** GET /product/brand : every brand that has at least one visible product. */
function api_product_brands(): void
{
    $rows = db()->query(
        "SELECT b.name AS brand, b.image,
                (SELECT pi.url FROM product_images pi JOIN products p2 ON p2.id = pi.product_id
                  WHERE p2.brand_id = b.id ORDER BY p2.id, pi.sort_order LIMIT 1) AS first_image
           FROM brands b
          WHERE EXISTS (SELECT 1 FROM products p WHERE p.brand_id = b.id AND " . VISIBLE . ")
          ORDER BY b.name"
    )->fetchAll();

    $brands = array_map(fn ($r) => [
        'brand' => $r['brand'],
        'image' => public_image_url($r['image'] ?: $r['first_image']) ?? '',
    ], $rows);

    json_response(200, ['message' => 'Brand fetches successflly.', 'data' => $brands]);
}

/** GET /product/brand/products?name=Chanel&page=&limit= */
function api_product_by_brand(): void
{
    $name = query('name');
    if ($name === null) {
        json_response(400, ['message' => "Brand name query paramter 'name' is required.", 'data' => []]);
    }
    product_page_reply('Products for brand fetched successfully.', ['b.name = ?'], [$name], 'p.id ASC');
}

/** Distinct, sorted list values of one type across visible products. */
function distinct_attribute(string $type): array
{
    return q(
        "SELECT DISTINCT TRIM(a.value) AS v
           FROM product_attributes a JOIN products p ON p.id = a.product_id
          WHERE a.type = ? AND " . VISIBLE . " AND TRIM(a.value) <> ''
          ORDER BY v",
        [$type]
    )->fetchAll(PDO::FETCH_COLUMN);
}

/** GET /product/discovery/moods */
function api_discovery_moods(): void
{
    json_response(200, ['message' => 'Unique moods fetched sucessfully.', 'data' => distinct_attribute('mood')]);
}

/** GET /product/discovery/occasions */
function api_discovery_occasions(): void
{
    json_response(200, [
        'message' => 'Unique occasions fetched successfully.',
        'data'    => distinct_attribute('occasion'),
    ]);
}

/** GET /product/discovery/notes : { top: [], middle: [], base: [] } */
function api_discovery_notes(): void
{
    json_response(200, [
        'message' => 'Unique fragrance notes fetched successfully.',
        'data'    => [
            'top'    => distinct_attribute('note_top'),
            'middle' => distinct_attribute('note_middle'),
            'base'   => distinct_attribute('note_base'),
        ],
    ]);
}

/** GET /product/discovery/scent-families */
function api_discovery_families(): void
{
    $families = db()->query(
        "SELECT DISTINCT TRIM(p.fragrance_family) AS v FROM products p
          WHERE " . VISIBLE . " AND TRIM(p.fragrance_family) <> '' ORDER BY v"
    )->fetchAll(PDO::FETCH_COLUMN);

    json_response(200, ['message' => 'Unique scent families fetched successfully.', 'data' => $families]);
}

/** GET /product/discovery/filter?mood=&note=&occasion=&family=&type=new|trending&page=&limit= */
function api_discovery_filter(): void
{
    $where = [];
    $params = [];

    if (($mood = query('mood')) !== null) {
        $where[] = has_attribute(['mood']);
        $params[] = $mood;
    }
    if (($note = query('note')) !== null) {
        $where[] = has_attribute(['note_top', 'note_middle', 'note_base']);
        $params[] = $note;
    }
    if (($occasion = query('occasion')) !== null) {
        $where[] = has_attribute(['occasion']);
        $params[] = $occasion;
    }
    if (($family = query('family')) !== null) {
        $where[] = 'p.fragrance_family = ?';
        $params[] = $family;
    }

    $orderBy = match (query('type')) {
        'trending' => 'p.sales_count DESC, p.id ASC',
        'new'      => 'p.created_at DESC, p.id DESC',
        default    => 'p.id ASC',
    };

    product_page_reply('Discovery filtered products fetched successfully.', $where, $params, $orderBy);
}

/** GET /product/detail/{id} */
function api_product_detail(string $id): void
{
    if (!ctype_digit($id)) {
        json_response(400, ['message' => 'Invalid product ID format.', 'data' => null]);
    }
    $product = find_product((int) $id);
    if ($product === null) {
        json_response(404, ['message' => 'Product not found', 'data' => null]);
    }
    json_response(200, ['message' => 'Product fetched sucessfully.', 'data' => $product]);
}

/** POST /product/batch  with a JSON list of ids, e.g. ["3", "7"]. Used by the cart. */
function api_product_batch(): void
{
    $ids = json_body();
    if (!is_array($ids) || !array_is_list($ids)) {
        json_response(400, ['message' => 'Request body must be an arrays of IDs', 'data' => []]);
    }
    if ($ids === []) {
        json_response(200, ['message' => 'No Ids provided.', 'data' => []]);
    }

    $valid = [];
    foreach ($ids as $id) {
        if ((is_string($id) || is_int($id)) && ctype_digit((string) $id)) {
            $valid[(int) $id] = true;
        }
    }
    if ($valid === []) {
        json_response(200, ['message' => 'No valid product IDs found.', 'data' => []]);
    }

    $in = implode(',', array_keys($valid));
    $rows = db()->query(product_select() . " WHERE p.id IN ($in) ORDER BY p.id")->fetchAll();

    json_response(200, ['message' => 'Products found sucessfully.', 'data' => hydrate_products($rows)]);
}


/**
 * GET /changes
 * A short fingerprint of the shop data. The app asks for it every few seconds and
 * reloads its screens when it changes, so edits made in the admin site show up straight away.
 * CHECKSUM TABLE notices every change (insert, update, delete), wherever it was made.
 * Orders are included so a status change in the admin site shows in "My orders".
 */
function api_changes(): void
{
    $parts = [];
    ensure_social_schema();
    foreach (db()->query('CHECKSUM TABLE products, product_images, product_attributes, brands, orders, product_reviews') as $row) {
        $parts[] = $row['Table'] . '=' . $row['Checksum'];
    }
    header('Cache-Control: no-store');
    json_response(200, ['message' => 'Data fingerprint', 'data' => ['version' => md5(implode('|', $parts))]]);
}
