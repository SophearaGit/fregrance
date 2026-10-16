<?php
/**
 * API entry point. Every request to /api/... lands here (see .htaccess) and is
 * sent to the matching function in app/api/*.php.
 *
 * The addresses and JSON replies match the original Node.js API, so the Flutter
 * app only needs its base URL changed.
 */
declare(strict_types=1);

require dirname(__DIR__) . '/app/bootstrap.php';
require APP_ROOT . '/app/http.php';
require APP_ROOT . '/app/products.php';
require APP_ROOT . '/app/api/auth.php';
require APP_ROOT . '/app/api/product.php';
require APP_ROOT . '/app/api/order.php';
require APP_ROOT . '/app/api/account.php';
require APP_ROOT . '/app/api/payway.php';

send_cors_headers();

// Browsers ask permission with an OPTIONS request before the real one.
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

set_exception_handler(function (Throwable $error): void {
    json_response(500, ['message' => 'Internal server error', 'error' => $error->getMessage()]);
});

if (app_config() === null) {
    json_response(503, [
        'message' => 'The backend is not installed yet. Open install.php in your browser first.',
        'error'   => 'NotInstalled',
    ]);
}

/** The part of the address after /api, for example "/product/feed". */
function request_path(): string
{
    if (!empty($_SERVER['PATH_INFO'])) {
        $path = $_SERVER['PATH_INFO'];
    } else {
        $path = rawurldecode((string) parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH));
        $base = backend_base_path() . '/api';
        if ($base !== '' && str_starts_with($path, $base)) {
            $path = substr($path, strlen($base));
        }
        if (str_starts_with($path, '/index.php')) {
            $path = substr($path, strlen('/index.php'));
        }
    }
    $path = '/' . trim($path, '/');
    return $path;
}

// [method, pattern, function]. Patterns are tried from top to bottom.
$routes = [
    ['GET',  '#^/(?:health)?$#',                      'api_health'],
    ['GET',  '#^/uploads/([A-Za-z0-9._-]+)$#',        'api_upload_file'],
    ['GET',  '#^/changes$#',                          'api_changes'],

    ['POST', '#^/auth/register$#',                    'api_auth_register'],
    ['POST', '#^/auth/login$#',                       'api_auth_login'],
    ['GET',  '#^/auth/google/config$#',               'api_auth_google_config'],
    ['POST', '#^/auth/google$#',                      'api_auth_google'],

    ['GET',  '#^/user$#',                             'api_user_me'],
    ['POST', '#^/user$#',                             'api_user_update'],
    ['POST', '#^/user/avatar$#',                      'api_user_avatar'],
    ['POST', '#^/user/password$#',                    'api_user_password'],
    ['GET',  '#^/wallet$#',                           'api_wallet'],
    ['GET',  '#^/address$#',                          'api_address_list'],
    ['POST', '#^/address/add$#',                      'api_address_create'],

    ['GET',  '#^/product$#',                          'api_product_index'],
    ['GET',  '#^/product/featured$#',                 'api_product_featured'],
    ['GET',  '#^/product/feed$#',                     'api_product_feed'],
    ['GET',  '#^/product/brand$#',                    'api_product_brands'],
    ['GET',  '#^/product/brand/products$#',           'api_product_by_brand'],
    ['GET',  '#^/product/discovery/moods$#',          'api_discovery_moods'],
    ['GET',  '#^/product/discovery/notes$#',          'api_discovery_notes'],
    ['GET',  '#^/product/discovery/occasions$#',      'api_discovery_occasions'],
    ['GET',  '#^/product/discovery/scent-families$#', 'api_discovery_families'],
    ['GET',  '#^/product/discovery/filter$#',         'api_discovery_filter'],
    // The app's cart posts its product ids to /product/cart; /product/batch is the original name.
    ['POST', '#^/product/(?:batch|cart|products/batch)$#', 'api_product_batch'],
    ['GET',  '#^/product/?detail/:?([^/]+)$#',        'api_product_detail'],
    ['GET',  '#^/product/:?([0-9]+)$#',               'api_product_detail'],

    ['GET',  '#^/order$#',                            'api_order_list'],
    ['POST', '#^/order$#',                            'api_order_create'],
    ['POST', '#^/order/payway$#',                     'api_order_payway_create'],
    ['POST', '#^/order/payway/check$#',               'api_order_payway_check'],
    ['GET',  '#^/payway/checkout/([A-Za-z0-9]{1,20})$#', 'api_payway_checkout_page'],
    ['GET',  '#^/payway/return$#',                    'api_payway_return'],
    ['POST', '#^/payway/callback$#',                  'api_payway_callback'],
    ['GET',  '#^/order/processing$#',                 'api_order_processing'],
    ['GET',  '#^/order/history$#',                    'api_order_history'],
    ['POST', '#^/order/([^/]+)/received$#',           'api_order_received'],
];

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$path = request_path();

foreach ($routes as [$routeMethod, $pattern, $handler]) {
    if ($method === $routeMethod && preg_match($pattern, $path, $matches)) {
        $handler(...array_slice($matches, 1));
        exit;
    }
}

json_response(404, ['message' => '[Server] Route not found.']);

// ---------------------------------------------------------------------------

function api_health(): void
{
    header('Content-Type: text/html; charset=utf-8');
    echo '[Server] Server is running...';
}

/** Serve an uploaded image (through PHP so the web app is allowed to load it). */
function api_upload_file(string $name): void
{
    $file = UPLOAD_DIR . '/' . basename($name);
    $types = ['jpg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp', 'gif' => 'image/gif'];
    $extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    if (!isset($types[$extension]) || !is_file($file)) {
        json_response(404, ['message' => 'Image not found.']);
    }
    header('Content-Type: ' . $types[$extension]);
    header('Content-Length: ' . filesize($file));
    header('Cache-Control: public, max-age=86400');
    readfile($file);
}
