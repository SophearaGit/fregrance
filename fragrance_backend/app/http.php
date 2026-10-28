<?php
/**
 * HTTP helpers for the API: JSON replies, request input, login tokens (JWT).
 */
declare(strict_types=1);

/** Send a JSON reply and stop. */
function json_response(int $status, array $body): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRESERVE_ZERO_FRACTION);
    exit;
}

/** Allow the Flutter web app (which runs on another localhost port) to call the API. */
function send_cors_headers(): void
{
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, Accept');
    header('Access-Control-Max-Age: 86400');
}

/** The decoded JSON request body (array), or null when there is none or it is not valid JSON. */
function json_body(): mixed
{
    static $body = false;
    if ($body === false) {
        $raw = file_get_contents('php://input');
        $body = ($raw === false || trim($raw) === '') ? null : json_decode($raw, true);
    }
    return $body;
}

/** A query-string value as a trimmed string, or null when missing or empty. */
function query(string $key): ?string
{
    $value = $_GET[$key] ?? null;
    if (!is_string($value)) {
        return null;
    }
    $value = trim($value);
    return $value === '' ? null : $value;
}

/** Page and limit from the query string, with the same defaults as the old API (1 and 10). */
function pagination_input(): array
{
    $page = (int) ($_GET['page'] ?? 0);
    $limit = (int) ($_GET['limit'] ?? 0);
    $page = $page > 0 ? $page : 1;
    $limit = $limit > 0 ? min($limit, 100) : 10;
    return [$page, $limit, ($page - 1) * $limit];
}

/** The "pagination" block of a list reply. */
function pagination_block(int $page, int $limit, int $total, int $returned): array
{
    return [
        'page'        => $page,
        'limit'       => $limit,
        'total'       => $total,
        'hasNext'     => (($page - 1) * $limit + $returned) < $total,
        'hasPrevious' => $page > 1,
    ];
}

// ---------------------------------------------------------------------------
// Login tokens (JWT, HS256), the same kind the old API issued
// ---------------------------------------------------------------------------

function base64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode(string $data): string|false
{
    return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4), true);
}

/** Create a signed token for a user. */
function jwt_create(array $user): string
{
    $config = app_config();
    $now = time();
    $header = ['alg' => 'HS256', 'typ' => 'JWT'];
    $payload = [
        'id'       => (string) $user['id'],
        'username' => $user['username'],
        'role'     => $user['role'],
        'iat'      => $now,
        'exp'      => $now + 86400 * (int) ($config['jwt_expires_days'] ?? 7),
    ];
    $unsigned = base64url_encode(json_encode($header)) . '.' . base64url_encode(json_encode($payload));
    $signature = hash_hmac('sha256', $unsigned, $config['jwt_secret'], true);
    return $unsigned . '.' . base64url_encode($signature);
}

/** Check a token and return its payload, or null when it is invalid or expired. */
function jwt_verify(string $token): ?array
{
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return null;
    }
    [$header64, $payload64, $signature64] = $parts;
    $header = json_decode((string) base64url_decode($header64), true);
    if (!is_array($header) || ($header['alg'] ?? '') !== 'HS256') {
        return null;
    }
    $expected = hash_hmac('sha256', $header64 . '.' . $payload64, app_config()['jwt_secret'], true);
    $given = base64url_decode($signature64);
    if ($given === false || !hash_equals($expected, $given)) {
        return null;
    }
    $payload = json_decode((string) base64url_decode($payload64), true);
    if (!is_array($payload) || (isset($payload['exp']) && time() >= (int) $payload['exp'])) {
        return null;
    }
    return $payload;
}

/** The Authorization header, wherever this web server puts it. */
function authorization_header(): ?string
{
    foreach (['HTTP_AUTHORIZATION', 'REDIRECT_HTTP_AUTHORIZATION'] as $key) {
        if (!empty($_SERVER[$key])) {
            return $_SERVER[$key];
        }
    }
    if (function_exists('getallheaders')) {
        foreach (getallheaders() as $name => $value) {
            if (strcasecmp($name, 'Authorization') === 0) {
                return $value;
            }
        }
    }
    return null;
}

function unauthorized(string $message): never
{
    json_response(401, ['success' => false, 'status' => 401, 'error' => 'UnauthorizedError', 'message' => $message]);
}

/**
 * Require a valid "Authorization: Bearer <token>" header and return the token payload
 * (id, username, role). Pass a role to also require that role.
 */
function require_auth(?string $role = null): array
{
    $header = authorization_header();
    if ($header === null) {
        unauthorized('Authorization required.');
    }
    $parts = explode(' ', trim($header));
    if (count($parts) < 2 || $parts[0] !== 'Bearer' || $parts[1] === '') {
        unauthorized('Invalid authorization header.');
    }
    $payload = jwt_verify($parts[1]);
    if ($payload === null) {
        unauthorized('Invalid or expired token.');
    }
    if ($role !== null && ($payload['role'] ?? null) !== $role) {
        $message = $role === 'user'
            ? 'This is an admin account. In the app, sign in with a customer account.'
            : 'You do not have permission.';
        json_response(403, ['success' => false, 'error' => 'ForbiddenError', 'message' => $message]);
    }
    return $payload;
}
