<?php
/**
 * GET photo_search.php?q=chanel+no+5
 * Looks for product photos in Open Beauty Facts (a free, open database of beauty
 * products and perfumes, https://world.openbeautyfacts.org). Used by the
 * "Find photos online" box on the product form. Replies with JSON.
 */
declare(strict_types=1);

require __DIR__ . '/_init.php';

header('Content-Type: application/json');
header('Cache-Control: no-store');

if (current_admin() === null) {
    http_response_code(401);
    exit(json_encode(['error' => 'Please sign in again.']));
}
session_write_close();

$query = trim((string) ($_GET['q'] ?? ''));
if (mb_strlen($query) < 2) {
    exit(json_encode(['results' => []]));
}

$url = 'https://world.openbeautyfacts.org/cgi/search.pl?' . http_build_query([
    'search_terms'  => $query,
    'search_simple' => 1,
    'action'        => 'process',
    'json'          => 1,
    'page_size'     => 24,
    'fields'        => 'code,product_name,brands,image_front_url,image_url,quantity',
]);

$curl = curl_init($url);
curl_setopt_array($curl, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => 15,
    CURLOPT_FOLLOWLOCATION => true,
    // Open Beauty Facts asks apps to say who they are.
    CURLOPT_USERAGENT      => 'FragranceShopAdmin/1.0 (school project)',
]);
foreach ([(string) ini_get('curl.cainfo'), 'C:/laragon/etc/ssl/cacert.pem',
          dirname((string) ($_SERVER['DOCUMENT_ROOT'] ?? '')) . '/etc/ssl/cacert.pem'] as $ca) {
    if ($ca !== '' && is_file($ca)) {
        curl_setopt($curl, CURLOPT_CAINFO, $ca);
        break;
    }
}
$body = curl_exec($curl);
$error = curl_error($curl);
$status = (int) curl_getinfo($curl, CURLINFO_HTTP_CODE);
curl_close($curl);

if ($body === false || $status >= 400) {
    http_response_code(502);
    exit(json_encode(['error' => 'Could not reach Open Beauty Facts' . ($error !== '' ? ": $error" : " (HTTP $status)") . '.']));
}

$data = json_decode((string) $body, true);
$results = [];
foreach ((is_array($data) ? ($data['products'] ?? []) : []) as $product) {
    $image = (string) ($product['image_front_url'] ?? $product['image_url'] ?? '');
    if ($image === '' || !preg_match('#^https://#', $image)) {
        continue; // only products that have a photo
    }
    // Ask for the larger version of the photo when there is one.
    $large = preg_replace('#\.(\d+)\.jpg$#', '.full.jpg', $image) ?? $image;
    $results[] = [
        'name'  => trim((string) ($product['product_name'] ?? '')) ?: 'Unnamed product',
        'brand' => trim((string) ($product['brands'] ?? '')),
        'size'  => trim((string) ($product['quantity'] ?? '')),
        'thumb' => $image,
        'image' => $large,
        'link'  => 'https://world.openbeautyfacts.org/product/' . rawurlencode((string) ($product['code'] ?? '')),
    ];
}

echo json_encode(['results' => $results, 'source' => 'Open Beauty Facts']);
