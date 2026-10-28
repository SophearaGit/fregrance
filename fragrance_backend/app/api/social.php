<?php
/**
 * Reviews and favorites.
 *
 * Reviews: a customer who bought a product (a paid order or later) can rate it
 * 1-5 stars with an optional comment; one review per customer per product
 * (sending again updates it). The product's rating becomes the average.
 *
 * Favorites: a customer's saved products (the heart button in the app).
 */
declare(strict_types=1);

/** The signed-in user's id when the request has a valid token, else null. */
function optional_user_id(): ?int
{
    $header = authorization_header();
    if ($header === null || !preg_match('/^Bearer\s+(\S+)$/', trim($header), $m)) {
        return null;
    }
    $payload = jwt_verify($m[1]);
    return $payload === null ? null : (int) $payload['id'];
}

/** Statuses that mean the customer really bought (and paid for) the product. */
const BOUGHT_STATUSES = "'paid','processing','shipping','delivered','received'";

function has_bought(int $userId, int $productId): bool
{
    return (bool) q('SELECT 1 FROM orders o JOIN order_items i ON i.order_id = o.id
                     WHERE o.user_id = ? AND i.product_id = ? AND o.status IN (' . BOUGHT_STATUSES . ') LIMIT 1',
                    [$userId, $productId])->fetchColumn();
}

function review_json(array $r, ?int $viewerId): array
{
    return [
        'id'        => (string) $r['id'],
        'productId' => (string) $r['product_id'],
        'rating'    => (int) $r['rating'],
        'comment'   => (string) $r['comment'],
        'userName'  => (string) ($r['fullname'] ?? ''),
        'userPhoto' => public_image_url($r['profile'] ?? null),
        'isMine'    => $viewerId !== null && (int) $r['user_id'] === $viewerId,
        'createdAt' => iso_date($r['created_at']),
        'updatedAt' => iso_date($r['updated_at']),
    ];
}

function product_exists(int $productId): bool
{
    return (bool) q("SELECT 1 FROM products WHERE id = ? AND status <> 'inactive'", [$productId])->fetchColumn();
}

/**
 * GET /product/{id}/reviews?page=&limit=
 * Summary (average, count, stars breakdown), the viewer's own review and whether
 * they may write one, plus a page of reviews (newest first).
 */
function api_product_reviews(string $id): void
{
    ensure_social_schema();
    $productId = (int) $id;
    if (!product_exists($productId)) {
        json_response(404, ['message' => 'Product not found.', 'data' => null]);
    }
    $viewerId = optional_user_id();
    [$page, $limit, $offset] = pagination_input();

    $summary = q('SELECT COUNT(*) AS n, AVG(rating) AS avg FROM product_reviews WHERE product_id = ?', [$productId])->fetch();
    $breakdown = ['5' => 0, '4' => 0, '3' => 0, '2' => 0, '1' => 0];
    foreach (q('SELECT rating, COUNT(*) AS n FROM product_reviews WHERE product_id = ? GROUP BY rating', [$productId]) as $row) {
        $breakdown[(string) $row['rating']] = (int) $row['n'];
    }

    $rows = q("SELECT r.*, u.fullname, u.profile FROM product_reviews r JOIN users u ON u.id = r.user_id
               WHERE r.product_id = ? ORDER BY r.updated_at DESC, r.id DESC LIMIT $limit OFFSET $offset",
              [$productId])->fetchAll();

    $mine = null;
    $canReview = false;
    if ($viewerId !== null) {
        $own = q('SELECT r.*, u.fullname, u.profile FROM product_reviews r JOIN users u ON u.id = r.user_id
                  WHERE r.product_id = ? AND r.user_id = ?', [$productId, $viewerId])->fetch();
        $mine = $own ? review_json($own, $viewerId) : null;
        $canReview = has_bought($viewerId, $productId);
    }

    $total = (int) $summary['n'];
    json_response(200, [
        'message'    => 'Reviews retrieved.',
        'data'       => [
            'average'   => $total ? round((float) $summary['avg'], 1) : 0,
            'count'     => $total,
            'breakdown' => $breakdown,
            'myReview'  => $mine,
            'canReview' => $canReview,
            'reviews'   => array_map(fn ($r) => review_json($r, $viewerId), $rows),
        ],
        'pagination' => pagination_block($page, $limit, $total, count($rows)),
    ]);
}

/** POST /product/{id}/reviews  { rating: 1-5, comment? }  Write or update your review. */
function api_product_review_save(string $id): void
{
    ensure_social_schema();
    $auth = require_auth('user');
    $userId = (int) $auth['id'];
    $productId = (int) $id;
    if (!product_exists($productId)) {
        json_response(404, ['message' => 'Product not found.', 'data' => null]);
    }
    if (!has_bought($userId, $productId)) {
        json_response(403, ['message' => 'You can review a product after you have bought it.', 'data' => null]);
    }
    $body = json_body();
    $rating = is_array($body) ? ($body['rating'] ?? null) : null;
    if (!is_int($rating) || $rating < 1 || $rating > 5) {
        json_response(400, ['message' => 'Choose a rating from 1 to 5 stars.', 'data' => null]);
    }
    $comment = mb_substr(body_string($body, 'comment'), 0, 1000);

    q('INSERT INTO product_reviews (product_id, user_id, rating, comment) VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE rating = VALUES(rating), comment = VALUES(comment), updated_at = CURRENT_TIMESTAMP',
      [$productId, $userId, $rating, $comment]);
    refresh_product_rating($productId);

    $row = q('SELECT r.*, u.fullname, u.profile FROM product_reviews r JOIN users u ON u.id = r.user_id
              WHERE r.product_id = ? AND r.user_id = ?', [$productId, $userId])->fetch();
    json_response(200, ['message' => 'Thanks for your review!', 'data' => review_json($row, $userId)]);
}

/** POST /review/{id}/delete  Remove your own review. */
function api_review_delete(string $id): void
{
    ensure_social_schema();
    $auth = require_auth('user');
    $row = q('SELECT * FROM product_reviews WHERE id = ? AND user_id = ?', [(int) $id, (int) $auth['id']])->fetch();
    if (!$row) {
        json_response(404, ['message' => 'Review not found.', 'data' => null]);
    }
    q('DELETE FROM product_reviews WHERE id = ?', [$row['id']]);
    refresh_product_rating((int) $row['product_id']);
    json_response(200, ['message' => 'Review deleted.', 'data' => ['id' => (string) $row['id']]]);
}

/**
 * GET /review/mine  Products the customer bought, newest purchase first,
 * each with their review (or null when not reviewed yet).
 */
function api_review_mine(): void
{
    ensure_social_schema();
    $auth = require_auth('user');
    $userId = (int) $auth['id'];
    $productIds = q('SELECT i.product_id, MAX(o.created_at) AS bought FROM orders o JOIN order_items i ON i.order_id = o.id
                     WHERE o.user_id = ? AND i.product_id IS NOT NULL AND o.status IN (' . BOUGHT_STATUSES . ')
                     GROUP BY i.product_id ORDER BY bought DESC LIMIT 100', [$userId])->fetchAll(PDO::FETCH_COLUMN);
    if (!$productIds) {
        json_response(200, ['message' => 'Nothing to review yet.', 'data' => []]);
    }
    $in = implode(',', array_map('intval', $productIds));
    $products = [];
    foreach (hydrate_products(db()->query(product_select() . " WHERE p.id IN ($in)")->fetchAll()) as $product) {
        $products[$product['id']] = $product;
    }
    $reviews = [];
    foreach (q("SELECT r.*, u.fullname, u.profile FROM product_reviews r JOIN users u ON u.id = r.user_id
                WHERE r.user_id = ? AND r.product_id IN ($in)", [$userId]) as $r) {
        $reviews[(string) $r['product_id']] = review_json($r, $userId);
    }
    $items = [];
    foreach ($productIds as $pid) {
        $key = (string) $pid;
        if (isset($products[$key])) {
            $items[] = ['product' => $products[$key], 'review' => $reviews[$key] ?? null];
        }
    }
    json_response(200, ['message' => 'Your purchases and reviews.', 'data' => $items]);
}

/** GET /favorite  The customer's saved products, newest first. */
function api_favorite_list(): void
{
    ensure_social_schema();
    $auth = require_auth('user');
    $rows = q(product_select() . " JOIN favorites f ON f.product_id = p.id
              WHERE f.user_id = ? AND p.status <> 'inactive' ORDER BY f.created_at DESC", [(int) $auth['id']])->fetchAll();
    json_response(200, ['message' => 'Favorites retrieved.', 'data' => hydrate_products($rows)]);
}

/** GET /favorite/ids  Just the ids, to fill in the hearts quickly. */
function api_favorite_ids(): void
{
    ensure_social_schema();
    $auth = require_auth('user');
    $ids = q('SELECT product_id FROM favorites WHERE user_id = ?', [(int) $auth['id']])->fetchAll(PDO::FETCH_COLUMN);
    json_response(200, ['message' => 'Favorite ids.', 'data' => array_map('strval', $ids)]);
}

/** POST /favorite/{productId}/toggle  Save or unsave a product. Replies { favorite: bool }. */
function api_favorite_toggle(string $id): void
{
    ensure_social_schema();
    $auth = require_auth('user');
    $userId = (int) $auth['id'];
    $productId = (int) $id;
    if (!product_exists($productId)) {
        json_response(404, ['message' => 'Product not found.', 'data' => null]);
    }
    $exists = q('SELECT 1 FROM favorites WHERE user_id = ? AND product_id = ?', [$userId, $productId])->fetchColumn();
    if ($exists) {
        q('DELETE FROM favorites WHERE user_id = ? AND product_id = ?', [$userId, $productId]);
    } else {
        q('INSERT INTO favorites (user_id, product_id) VALUES (?, ?)', [$userId, $productId]);
    }
    json_response(200, [
        'message' => $exists ? 'Removed from favorites.' : 'Saved to favorites.',
        'data'    => ['favorite' => !$exists, 'productId' => (string) $productId],
    ]);
}
