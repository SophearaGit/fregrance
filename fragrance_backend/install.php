<?php
/**
 * One-time setup. Creates the MySQL database and tables, loads the starting data,
 * creates the first admin account and writes config.php.
 *
 * Open it in the browser:  http://localhost/fregrance_all/fragrance_backend/install.php
 * To run it again later, delete config.php first.
 */
declare(strict_types=1);

require __DIR__ . '/app/bootstrap.php';
require APP_ROOT . '/app/sql.php';

$installed = app_config() !== null;
$errors = [];
$done = false;
$manualConfig = null;

$input = [
    'host'       => '127.0.0.1',
    'port'       => '3306',
    'user'       => 'root',
    'pass'       => '',
    'name'       => 'fragrance_db',
    'sample'     => '1',
    'replace'    => '',
    'admin_name' => '',
    'admin_email' => '',
];

$checks = [
    ['PHP 8.1 or newer (this is ' . PHP_VERSION . ')', PHP_VERSION_ID >= 80100],
    ['PHP extension pdo_mysql is enabled', extension_loaded('pdo_mysql')],
    ['The fragrance_backend folder is writable', is_writable(APP_ROOT)],
    ['The uploads folder is writable', is_dir(UPLOAD_DIR) ? is_writable(UPLOAD_DIR) : is_writable(APP_ROOT)],
];
$checksPass = !in_array(false, array_column($checks, 1), true);

if (!$installed && $checksPass && ($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
    foreach ($input as $key => $default) {
        $input[$key] = trim((string) ($_POST[$key] ?? ''));
    }
    $input['pass'] = (string) ($_POST['pass'] ?? '');
    $adminPassword = (string) ($_POST['admin_password'] ?? '');

    if (!preg_match('/^[A-Za-z0-9_]{1,64}$/', $input['name'])) {
        $errors[] = 'The database name may only contain letters, numbers and underscores.';
    }
    if ($input['host'] === '' || $input['user'] === '' || !ctype_digit($input['port'])) {
        $errors[] = 'Fill in the MySQL host, port and user.';
    }
    if ($input['admin_name'] === '') {
        $errors[] = 'Enter a name for the admin account.';
    }
    if (!filter_var($input['admin_email'], FILTER_VALIDATE_EMAIL)) {
        $errors[] = 'Enter a valid email for the admin account.';
    }
    if (strlen($adminPassword) < 8) {
        $errors[] = 'The admin password must be at least 8 characters.';
    }
    $seedFile = APP_ROOT . '/database/seed.sql';
    if ($input['sample'] !== '' && $input['admin_email'] !== ''
        && stripos((string) file_get_contents($seedFile), "'" . $input['admin_email'] . "'") !== false) {
        $errors[] = 'That email belongs to a sample customer in the starting data. Use a different email for the admin.';
    }

    $db = ['host' => $input['host'], 'port' => (int) $input['port'], 'name' => $input['name'],
           'user' => $input['user'], 'pass' => $input['pass']];

    if (!$errors) {
        try {
            $pdo = db_connect($db, false);
        } catch (PDOException $error) {
            $errors[] = 'Could not connect to MySQL. Is Laragon running (Start All)? Details: ' . $error->getMessage();
        }
    }

    if (!$errors) {
        try {
            $pdo->exec("CREATE DATABASE IF NOT EXISTS `{$db['name']}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
            $pdo->exec("USE `{$db['name']}`");

            $hasTables = (bool) $pdo->query("SHOW TABLES LIKE 'products'")->fetchColumn();
            if ($hasTables && $input['replace'] === '') {
                $errors[] = "The database \"{$db['name']}\" already has the shop tables. Tick \"Replace existing tables\" "
                          . 'to start again (this deletes the data in them), or choose another database name.';
            } else {
                run_sql_file($pdo, APP_ROOT . '/database/schema.sql');
                if ($input['sample'] !== '') {
                    run_sql_file($pdo, $seedFile);
                }

                // First admin account. The username is taken from the email and made unique.
                $username = strtolower(preg_replace('/[^A-Za-z0-9]/', '', strstr($input['admin_email'], '@', true))) ?: 'admin';
                $exists = $pdo->prepare('SELECT 1 FROM users WHERE username = ?');
                $candidate = $username;
                for ($n = 2; $exists->execute([$candidate]) && $exists->fetchColumn(); $n++) {
                    $candidate = $username . $n;
                }
                $pdo->prepare('INSERT INTO users (fullname, username, email, password_hash, role) VALUES (?, ?, ?, ?, ?)')
                    ->execute([$input['admin_name'], $candidate, strtolower($input['admin_email']),
                               password_hash($adminPassword, PASSWORD_BCRYPT, ['cost' => 12]), 'admin']);

                $config = [
                    'db'                 => $db,
                    'jwt_secret'         => bin2hex(random_bytes(32)),
                    'jwt_expires_days'   => 7,
                    'new_wallet_balance' => 0,
                ];
                $php = "<?php\n// Settings written by install.php. Delete this file to run the installer again.\n"
                     . "// db: MySQL connection.  jwt_secret: signs app login tokens (keep private).\n"
                     . "// jwt_expires_days: how long an app login lasts.\n"
                     . "// new_wallet_balance: wallet balance given to a customer who registers.\n"
                     . 'return ' . var_export($config, true) . ";\n";
                if (@file_put_contents(CONFIG_FILE, $php) === false) {
                    $manualConfig = $php;
                }
                $done = true;
            }
        } catch (Throwable $error) {
            $errors[] = 'Setup stopped: ' . $error->getMessage();
        }
    }
}

$base = backend_base_path();
$apiUrl = api_base_url();
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Fragrance backend setup</title>
<link rel="stylesheet" href="admin/assets/admin.css">
</head>
<body>
<div class="center-page">
  <div class="logo">Fragrance <span>backend setup</span></div>

<?php if ($done): ?>
  <div class="flash ok">The database is ready and your admin account was created.</div>
  <?php if ($manualConfig !== null): ?>
    <div class="flash bad">
      The settings file could not be written. Create <code>fragrance_backend/config.php</code> with this content:
    </div>
    <pre class="code"><?= e($manualConfig) ?></pre>
  <?php endif; ?>
  <div class="card">
    <h2>Next steps</h2>
    <p><a class="btn primary" href="admin/">Open the admin site</a></p>
    <p>The app's API address is:</p>
    <pre class="code"><?= e($apiUrl) ?></pre>
    <p class="muted small">It is already set in the Flutter app
      (<code>lib/core/network/api_config.dart</code>). Check that the API answers:
      <a href="api/health">api/health</a> and <a href="api/product/featured">api/product/featured</a>.</p>
  </div>

<?php elseif ($installed): ?>
  <div class="flash info">The backend is already installed.</div>
  <div class="card">
    <p><a class="btn primary" href="admin/">Open the admin site</a></p>
    <p>API address for the app:</p>
    <pre class="code"><?= e($apiUrl) ?></pre>
    <p class="muted small">To run this setup again, delete <code>fragrance_backend/config.php</code> and reload this page.</p>
  </div>

<?php else: ?>
  <div class="card">
    <h2>Checks</h2>
    <ul class="checks">
      <?php foreach ($checks as [$label, $ok]): ?>
        <li class="<?= $ok ? 'pass' : 'fail' ?>"><?= e($label) ?></li>
      <?php endforeach; ?>
    </ul>
    <?php if (!$checksPass): ?>
      <p class="muted small">Fix the items marked with a cross, then reload this page.</p>
    <?php endif; ?>
  </div>

  <?php if ($errors): ?>
    <div class="flash bad">
      <?= count($errors) === 1 ? e($errors[0]) : '<ul><li>' . implode('</li><li>', array_map('e', $errors)) . '</li></ul>' ?>
    </div>
  <?php endif; ?>

  <?php if ($checksPass): ?>
  <form method="post" autocomplete="off">
    <div class="card">
      <h2>MySQL connection</h2>
      <p class="muted small">Laragon's defaults are already filled in: user <code>root</code> with an empty password.</p>
      <div class="grid">
        <div class="col-8"><label for="host">Host</label>
          <input type="text" id="host" name="host" value="<?= e($input['host']) ?>" required></div>
        <div class="col-4"><label for="port">Port</label>
          <input type="text" id="port" name="port" value="<?= e($input['port']) ?>" required></div>
        <div class="col-6"><label for="user">User</label>
          <input type="text" id="user" name="user" value="<?= e($input['user']) ?>" required></div>
        <div class="col-6"><label for="pass">Password</label>
          <input type="password" id="pass" name="pass" value="<?= e($input['pass']) ?>"></div>
        <div class="col-12"><label for="name">Database name</label>
          <input type="text" id="name" name="name" value="<?= e($input['name']) ?>" required>
          <div class="hint">Created automatically if it does not exist.</div></div>
        <div class="col-12 check-row">
          <input type="checkbox" id="sample" name="sample" value="1" <?= $input['sample'] !== '' ? 'checked' : '' ?>>
          <label for="sample">Load the starting data (38 products, 20 brands and the sample customer from the old database)</label>
        </div>
        <div class="col-12 check-row">
          <input type="checkbox" id="replace" name="replace" value="1" <?= $input['replace'] !== '' ? 'checked' : '' ?>>
          <label for="replace">Replace existing tables (deletes any shop data already in this database)</label>
        </div>
      </div>
    </div>

    <div class="card">
      <h2>Admin account</h2>
      <p class="muted small">You will sign in to the admin site with this email and password.</p>
      <div class="grid">
        <div class="col-12"><label for="admin_name">Name</label>
          <input type="text" id="admin_name" name="admin_name" value="<?= e($input['admin_name']) ?>" required></div>
        <div class="col-6"><label for="admin_email">Email</label>
          <input type="email" id="admin_email" name="admin_email" value="<?= e($input['admin_email']) ?>" required></div>
        <div class="col-6"><label for="admin_password">Password</label>
          <input type="password" id="admin_password" name="admin_password" minlength="8" required>
          <div class="hint">At least 8 characters.</div></div>
      </div>
    </div>

    <div class="form-actions">
      <button class="btn primary" type="submit">Set up the database</button>
    </div>
  </form>
  <?php endif; ?>
<?php endif; ?>
</div>
</body>
</html>
