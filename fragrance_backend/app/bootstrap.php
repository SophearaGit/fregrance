<?php
/**
 * Shared setup for the API, the admin site and the installer.
 * Loads config.php, opens the MySQL connection and defines small helpers.
 */
declare(strict_types=1);

define('APP_ROOT', dirname(__DIR__));
define('CONFIG_FILE', APP_ROOT . '/config.php');
define('UPLOAD_DIR', APP_ROOT . '/uploads');

date_default_timezone_set('UTC');
mb_internal_encoding('UTF-8');

/** The settings saved by install.php, or null when the backend is not installed yet. */
function app_config(): ?array
{
    static $config = false;
    if ($config === false) {
        $config = is_file(CONFIG_FILE) ? require CONFIG_FILE : null;
        if (!is_array($config)) {
            $config = null;
        }
    }
    return $config;
}

/** Open a PDO connection. Pass $withDatabase = false to connect before the database exists. */
function db_connect(array $db, bool $withDatabase = true): PDO
{
    $dsn = sprintf('mysql:host=%s;port=%d;charset=utf8mb4', $db['host'], (int) $db['port']);
    if ($withDatabase) {
        $dsn .= ';dbname=' . $db['name'];
    }
    $pdo = new PDO($dsn, $db['user'], $db['pass'], [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
    // Dates are stored and read in UTC; the admin site converts them for display.
    $pdo->exec("SET time_zone = '+00:00'");
    return $pdo;
}

/** The shared database connection. */
function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $config = app_config();
        if ($config === null) {
            throw new RuntimeException('The backend is not installed yet. Open install.php first.');
        }
        $pdo = db_connect($config['db']);
    }
    return $pdo;
}

/** Run a prepared statement and return it. */
function q(string $sql, array $params = []): PDOStatement
{
    $stmt = db()->prepare($sql);
    $stmt->execute($params);
    return $stmt;
}

/** Escape text for HTML output. */
function e(mixed $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/** Escape the wildcard characters of a LIKE pattern. */
function like_escape(string $value): string
{
    return addcslashes($value, '\\%_');
}

/** MySQL "2026-09-25 19:57:49" (UTC) to the ISO format the app parses: "2026-09-25T19:57:49.000Z". */
function iso_date(?string $mysqlDate): ?string
{
    if ($mysqlDate === null || $mysqlDate === '') {
        return null;
    }
    return str_replace(' ', 'T', substr($mysqlDate, 0, 19)) . '.000Z';
}

/**
 * URL path of the backend folder, for example "/fregrance_all/fragrance_backend".
 * Worked out from where the running script sits inside the backend folder.
 */
function backend_base_path(): string
{
    static $base = null;
    if ($base === null) {
        $scriptFile = str_replace('\\', '/', (string) realpath($_SERVER['SCRIPT_FILENAME'] ?? ''));
        $root = str_replace('\\', '/', (string) realpath(APP_ROOT));
        $scriptName = str_replace('\\', '/', $_SERVER['SCRIPT_NAME'] ?? '');
        $relative = ltrim(substr($scriptFile, strlen($root)), '/');   // e.g. "api/index.php"
        $depth = substr_count($relative, '/') + 1;                    // segments to strip
        $parts = explode('/', $scriptName);
        $base = rtrim(implode('/', array_slice($parts, 0, max(1, count($parts) - $depth))), '/');
    }
    return $base;
}

/** "http://localhost" style origin of the current request. */
function request_origin(): string
{
    $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    return ($https ? 'https' : 'http') . '://' . $host;
}

/** Full address of the API, for example "http://localhost/fregrance_all/fragrance_backend/api". */
function api_base_url(): string
{
    return request_origin() . backend_base_path() . '/api';
}

/**
 * Turn a stored image value into an address the app can load.
 * Web addresses are returned unchanged; uploaded files ("uploads/x.jpg") are served by the API.
 */
function public_image_url(?string $stored): ?string
{
    if ($stored === null || $stored === '') {
        return $stored;
    }
    if (preg_match('#^https?://#i', $stored)) {
        return $stored;
    }
    return api_base_url() . '/' . ltrim($stored, '/');
}
