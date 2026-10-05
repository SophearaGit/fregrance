<?php
/**
 * Loaded first by every admin page: session, sign-in check, form protection,
 * one-time messages and the shared page layout.
 */
declare(strict_types=1);

require dirname(__DIR__) . '/app/bootstrap.php';
require APP_ROOT . '/app/products.php';

if (app_config() === null) {
    header('Location: ../install.php');
    exit;
}

// Show a readable message instead of a blank page if something unexpected goes wrong.
set_exception_handler(function (Throwable $error): void {
    http_response_code(500);
    echo '<p style="font-family:sans-serif;padding:24px">Something went wrong: ' . e($error->getMessage())
       . '<br><a href="index.php">Back to the dashboard</a></p>';
});

session_name('fragrance_admin');
session_set_cookie_params(['httponly' => true, 'samesite' => 'Lax', 'path' => backend_base_path() . '/admin']);
session_start();

function redirect(string $to): never
{
    header('Location: ' . $to);
    exit;
}

/** The signed-in admin's user row, or null. */
function current_admin(): ?array
{
    static $admin = false;
    if ($admin === false) {
        $admin = null;
        if (!empty($_SESSION['admin_id'])) {
            $row = q("SELECT id, fullname, email FROM users WHERE id = ? AND role = 'admin'",
                     [(int) $_SESSION['admin_id']])->fetch();
            $admin = $row ?: null;
        }
    }
    return $admin;
}

/** Send visitors who are not signed in to the sign-in page. */
function require_admin(): array
{
    $admin = current_admin();
    if ($admin === null) {
        redirect('login.php');
    }
    return $admin;
}

// ---- Protection against forged form posts (CSRF) ----

function csrf_token(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(24));
    }
    return $_SESSION['csrf'];
}

function csrf_field(): string
{
    return '<input type="hidden" name="csrf" value="' . e(csrf_token()) . '">';
}

/** Call at the top of every POST handler. */
function verify_csrf(): void
{
    if (!hash_equals(csrf_token(), (string) ($_POST['csrf'] ?? ''))) {
        http_response_code(400);
        exit('This form has expired. Go back, reload the page and try again.');
    }
}

function is_post(): bool
{
    return ($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST';
}

// ---- One-time messages shown on the next page ----

function flash(string $type, string $message): void
{
    $_SESSION['flash'][] = [$type, $message];
}

function take_flashes(): array
{
    $flashes = $_SESSION['flash'] ?? [];
    unset($_SESSION['flash']);
    return $flashes;
}

// ---- Small display helpers ----

/** <img src> for a stored image value (web address or "uploads/<file>"). */
function admin_image_src(?string $stored): string
{
    if ($stored === null || $stored === '') {
        return '';
    }
    return preg_match('#^https?://#i', $stored) ? $stored : '../' . ltrim($stored, '/');
}

/** A date shown in the visitor's own time zone (the small script in the footer converts it). */
function show_date(?string $mysqlDate): string
{
    if (!$mysqlDate) {
        return '';
    }
    return '<time datetime="' . e(iso_date($mysqlDate)) . '">' . e(substr($mysqlDate, 0, 16)) . ' UTC</time>';
}

function money(mixed $amount, string $currency = 'USD'): string
{
    return e(number_format((float) $amount, 2) . ' ' . $currency);
}

function status_badge(string $status): string
{
    $class = match ($status) {
        'active', 'paid', 'delivered', 'received' => 'ok',
        'out_of_stock', 'pending', 'processing', 'shipping' => 'warn',
        'cancelled', 'failed' => 'bad',
        default => '',
    };
    return '<span class="badge ' . $class . '">' . e(ucfirst(str_replace('_', ' ', $status))) . '</span>';
}

/** Split typed text into a clean list: trimmed, no empty items, no repeats. */
function parse_list(string $text, bool $splitOnCommas): array
{
    $parts = preg_split($splitOnCommas ? '/[\r\n,]+/' : '/[\r\n]+/', $text) ?: [];
    $seen = [];
    $list = [];
    foreach ($parts as $part) {
        $part = trim(preg_replace('/\s+/', ' ', $part));
        $key = mb_strtolower($part);
        if ($part !== '' && !isset($seen[$key])) {
            $seen[$key] = true;
            $list[] = mb_substr($part, 0, 500);
        }
    }
    return $list;
}

/** Page number links under a table. */
function pager(int $page, int $pages, array $query): string
{
    if ($pages <= 1) {
        return '';
    }
    $link = fn (int $p) => '?' . e(http_build_query(array_merge($query, ['page' => $p])));
    $html = '<div class="pager"><span class="muted small">Page ' . $page . ' of ' . $pages . '</span>';
    if ($page > 1) {
        $html .= '<a class="btn small" href="' . $link($page - 1) . '">Previous</a>';
    }
    if ($page < $pages) {
        $html .= '<a class="btn small" href="' . $link($page + 1) . '">Next</a>';
    }
    return $html . '</div>';
}

// ---- Page layout ----

function admin_header(string $title, string $active = ''): void
{
    $admin = current_admin();
    $nav = [
        'dashboard' => ['index.php', 'Dashboard'],
        'products'  => ['products.php', 'Products'],
        'brands'    => ['brands.php', 'Brands'],
        'orders'    => ['orders.php', 'Orders'],
        'users'     => ['users.php', 'Users'],
    ];
    ?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
<title><?= e($title) ?> · Fragrance admin</title>
<link rel="stylesheet" href="assets/admin.css">
</head>
<body>
<div class="shell">
  <nav class="sidebar">
    <div class="brand">Fragrance<span>Admin</span></div>
    <?php foreach ($nav as $key => [$href, $label]): ?>
      <a href="<?= $href ?>" class="<?= $key === $active ? 'active' : '' ?>"><?= $label ?></a>
    <?php endforeach; ?>
    <div class="spacer"></div>
    <div class="who">
      <?= e($admin['fullname'] ?? '') ?>
      <form method="post" action="logout.php" style="margin-top:8px">
        <?= csrf_field() ?>
        <button class="btn small" type="submit">Sign out</button>
      </form>
    </div>
  </nav>
  <main class="main">
    <?php foreach (take_flashes() as [$type, $message]): ?>
      <div class="flash <?= e($type) ?>"><?= e($message) ?></div>
    <?php endforeach;
}

function admin_footer(): void
{
    ?>
  </main>
</div>
<script>
// Show dates in this computer's time zone, and ask before deleting.
document.querySelectorAll('time[datetime]').forEach(function (el) {
  var d = new Date(el.getAttribute('datetime'));
  if (!isNaN(d)) {
    el.textContent = d.toLocaleString(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  }
});
document.querySelectorAll('form[data-confirm]').forEach(function (form) {
  form.addEventListener('submit', function (event) {
    if (!window.confirm(form.getAttribute('data-confirm'))) event.preventDefault();
  });
});
</script>
</body>
</html>
    <?php
}
