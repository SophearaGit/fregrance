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

/** "Wallet", "ABA PayWay", ... */
function payment_label(string $method): string
{
    return $method === 'aba_payway' ? 'ABA PayWay' : ucfirst(str_replace('_', ' ', $method));
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
<link rel="stylesheet" href="assets/admin.css?v=<?= filemtime(__DIR__ . '/assets/admin.css') ?>">
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
(function () {
  'use strict';

  function store(key, value) {
    try {
      if (value === undefined) return window.localStorage.getItem(key);
      window.localStorage.setItem(key, value);
    } catch (e) { return null; }
  }

  // Dates in this computer's time zone.
  function showDates(root) {
    root.querySelectorAll('time[datetime]').forEach(function (el) {
      var d = new Date(el.getAttribute('datetime'));
      if (!isNaN(d)) {
        el.textContent = d.toLocaleString(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
      }
    });
  }

  // Ask before deleting.
  function confirmForms(root) {
    root.querySelectorAll('form[data-confirm]').forEach(function (form) {
      form.addEventListener('submit', function (event) {
        if (!window.confirm(form.getAttribute('data-confirm'))) event.preventDefault();
      });
    });
  }

  // List / Grid switch on every table. The choice is remembered per page.
  var ICON_LIST = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/></svg>';
  var ICON_GRID = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>';

  function viewSwitches(root) {
    root.querySelectorAll('.table-wrap').forEach(function (wrap, index) {
      var table = wrap.querySelector('table');
      if (!table || !table.tHead) return;

      // Label every cell with its column name, for the grid cards.
      var headers = Array.prototype.map.call(table.tHead.rows[0].cells, function (th) { return th.textContent.trim(); });
      Array.prototype.forEach.call(table.tBodies[0] ? table.tBodies[0].rows : [], function (row) {
        Array.prototype.forEach.call(row.cells, function (cell, i) {
          if (headers[i]) cell.setAttribute('data-label', headers[i]);
          if (cell.querySelector('form, .btn')) cell.classList.add('actions');
        });
      });

      var key = 'admin-view:' + location.pathname + ':' + index;
      var bar = document.createElement('div');
      bar.className = 'view-bar';
      bar.innerHTML = '<button type="button" data-view="list" title="Show as a list">' + ICON_LIST + 'List</button>'
                    + '<button type="button" data-view="grid" title="Show as cards">' + ICON_GRID + 'Grid</button>';
      wrap.parentNode.insertBefore(bar, wrap);

      function apply(view) {
        wrap.classList.toggle('as-grid', view === 'grid');
        bar.querySelectorAll('button').forEach(function (b) {
          b.setAttribute('aria-pressed', b.getAttribute('data-view') === view ? 'true' : 'false');
        });
      }
      bar.addEventListener('click', function (event) {
        var button = event.target.closest('button[data-view]');
        if (!button) return;
        var view = button.getAttribute('data-view');
        store(key, view);
        apply(view);
      });
      apply(store(key) || 'list');
    });
  }

  // A photo that is missing or fails to load shows the "No image" picture.
  var NO_IMAGE = 'assets/no-image.svg';
  document.addEventListener('error', function (event) {
    var img = event.target;
    if (img.tagName === 'IMG' && img.getAttribute('src') !== NO_IMAGE && !img.dataset.noFallback) {
      img.src = NO_IMAGE;
    }
  }, true);

  // Filters (search box and drop-downs above a table) apply as you type or pick.
  function liveFilters(root) {
    root.querySelectorAll('form.toolbar[method="get"], form.toolbar:not([method])').forEach(function (form) {
      if (form.dataset.live) return;
      form.dataset.live = '1';
      var submit = form.querySelector('button[type="submit"], button:not([type])');
      if (submit) submit.hidden = true;
      var timer, request = 0;

      function run() {
        var params = new URLSearchParams(new FormData(form));
        Array.from(params.keys()).forEach(function (key) { if (params.get(key) === '') params.delete(key); });
        params.delete('page');
        var url = location.pathname + (params.toString() ? '?' + params : '');
        var mine = ++request;
        form.classList.add('loading');
        fetch(url, { credentials: 'same-origin', cache: 'no-store' })
          .then(function (r) { return r.text(); })
          .then(function (html) {
            if (mine !== request) return; // a newer search took over
            var doc = new DOMParser().parseFromString(html, 'text/html');
            // Swap the results and the count; keep the filter form (and its cursor) as it is.
            ['.page-head', '.card.flush'].forEach(function (selector) {
              var now = document.querySelectorAll('main.main ' + selector);
              var fresh = doc.querySelectorAll('main.main ' + selector);
              now.forEach(function (el, i) {
                if (!fresh[i]) return;
                var copy = document.importNode(fresh[i], true);
                el.replaceWith(copy);
                enhance(copy);
              });
            });
            history.replaceState(null, '', url);
          })
          .finally(function () { if (mine === request) form.classList.remove('loading'); });
      }

      form.addEventListener('input', function (event) {
        if (event.target.matches('input[type="search"], input[type="text"]')) {
          clearTimeout(timer);
          timer = setTimeout(run, 300);
        }
      });
      form.addEventListener('change', function (event) {
        if (event.target.matches('select')) { clearTimeout(timer); run(); }
      });
      form.addEventListener('submit', function (event) { event.preventDefault(); clearTimeout(timer); run(); });
    });
  }

  function enhance(root) {
    showDates(root);
    confirmForms(root);
    viewSwitches(root);
    liveFilters(root);
  }
  enhance(document);

  // ---- Live updates: reload the page content when the shop data changes ----
  var main = document.querySelector('main.main');
  if (!main || !main.querySelector('.table-wrap')) return; // forms only: nothing to keep live

  var dirty = false;          // the admin started typing in a form on this page
  var version = null;
  var busy = false;
  main.addEventListener('input', function (e) { if (!e.target.closest('form.toolbar')) dirty = true; });
  main.addEventListener('change', function (e) {
    if (!e.target.closest('.view-bar') && !e.target.closest('form.toolbar')) dirty = true;
  });

  var brand = document.querySelector('.sidebar .brand');
  var dot = document.createElement('div');
  dot.className = 'live-dot';
  dot.textContent = 'Live';
  dot.title = 'This page updates by itself when orders, payments or products change.';
  if (brand) brand.insertAdjacentElement('afterend', dot);

  var toast = document.createElement('div');
  toast.className = 'live-toast';
  document.body.appendChild(toast);
  function say(text) {
    toast.textContent = text;
    toast.classList.add('show');
    clearTimeout(say.timer);
    say.timer = setTimeout(function () { toast.classList.remove('show'); }, 3000);
  }

  function rowKeys(root) {
    var keys = {};
    root.querySelectorAll('.table-wrap tbody tr').forEach(function (tr) { keys[tr.textContent.replace(/\s+/g, ' ').trim()] = true; });
    return keys;
  }

  function reloadContent() {
    var before = rowKeys(main);
    return fetch(location.href, { credentials: 'same-origin', cache: 'no-store' })
      .then(function (r) { return r.text(); })
      .then(function (html) {
        var doc = new DOMParser().parseFromString(html, 'text/html');
        var fresh = doc.querySelector('main.main');
        if (!fresh) return;
        fresh.querySelectorAll('.flash').forEach(function (f) { f.remove(); });
        var scroll = window.scrollY;
        main.innerHTML = fresh.innerHTML;
        enhance(main);
        main.querySelectorAll('.table-wrap tbody tr').forEach(function (tr) {
          if (!before[tr.textContent.replace(/\s+/g, ' ').trim()]) tr.classList.add('flash-new');
        });
        window.scrollTo(0, scroll);
        say('Updated just now');
      });
  }

  function check() {
    if (busy || document.hidden) return;
    busy = true;
    fetch('live.php', { credentials: 'same-origin', cache: 'no-store' })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (data) {
        if (!data || !data.version) { dot.classList.add('off'); return; }
        dot.classList.remove('off');
        if (version !== null && data.version !== version) {
          var typing = document.activeElement && main.contains(document.activeElement)
                       && /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName);
          if (dirty || typing) {
            if (!check.told) say('New changes. They will show when you finish editing.');
            check.told = true;
            return;
          }
          check.told = false;
          version = data.version;
          return reloadContent();
        }
        version = data.version;
      })
      .catch(function () { dot.classList.add('off'); })
      .then(function () { busy = false; });
  }
  check();
  setInterval(check, 4000);
  document.addEventListener('visibilitychange', function () { if (!document.hidden) check(); });
})();
</script>
</body>
</html>
    <?php
}
