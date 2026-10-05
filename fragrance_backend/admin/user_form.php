<?php
/** Add a user, or edit one (user_form.php?id=5): details, role, password and wallet balance. */
declare(strict_types=1);
require __DIR__ . '/_init.php';
$admin = require_admin();

$id = isset($_GET['id']) ? (int) $_GET['id'] : null;
$existing = null;
if ($id !== null) {
    $existing = q('SELECT u.*, w.balance FROM users u LEFT JOIN wallets w ON w.user_id = u.id WHERE u.id = ?', [$id])->fetch();
    if (!$existing) {
        flash('bad', 'That user no longer exists.');
        redirect('users.php');
    }
}
$isSelf = $existing && (int) $existing['id'] === (int) $admin['id'];

$form = [
    'fullname' => $existing['fullname'] ?? '',
    'username' => $existing['username'] ?? '',
    'email'    => $existing['email'] ?? '',
    'role'     => $existing['role'] ?? 'user',
    'profile'  => $existing['profile'] ?? '',
    'balance'  => (string) (float) ($existing['balance'] ?? 0),
];
$errors = [];

if (is_post()) {
    verify_csrf();
    foreach ($form as $key => $unused) {
        $form[$key] = trim((string) ($_POST[$key] ?? ''));
    }
    $form['username'] = strtolower($form['username']);
    $form['email'] = strtolower($form['email']);
    $password = (string) ($_POST['password'] ?? '');
    if ($isSelf) {
        $form['role'] = 'admin';   // you cannot remove your own admin access
    }

    if ($form['fullname'] === '') {
        $errors[] = 'Enter the full name.';
    }
    if (!preg_match('/^[a-z0-9._-]{2,60}$/', $form['username'])) {
        $errors[] = 'The username needs 2 to 60 letters, numbers, dots, dashes or underscores.';
    }
    if (!filter_var($form['email'], FILTER_VALIDATE_EMAIL)) {
        $errors[] = 'Enter a valid email.';
    }
    if (!in_array($form['role'], ['user', 'admin'], true)) {
        $errors[] = 'Choose a role.';
    }
    if ($form['profile'] !== '' && !preg_match('#^https?://\S+$#i', $form['profile'])) {
        $errors[] = 'The profile picture address must start with http:// or https://.';
    }
    if (!is_numeric($form['balance']) || (float) $form['balance'] < 0) {
        $errors[] = 'The wallet balance must be 0 or more.';
    }
    if (!$existing && $password === '') {
        $errors[] = 'Enter a password for the new user.';
    } elseif ($password !== '' && strlen($password) < 8) {
        $errors[] = 'The password must be at least 8 characters.';
    }
    if (!$errors && q('SELECT 1 FROM users WHERE (email = ? OR username = ?) AND id <> ?',
                      [$form['email'], $form['username'], $id ?? 0])->fetchColumn()) {
        $errors[] = 'Another user already has that email or username.';
    }

    if (!$errors) {
        $pdo = db();
        $pdo->beginTransaction();
        try {
            $profile = $form['profile'] === '' ? null : $form['profile'];
            if ($existing) {
                q('UPDATE users SET fullname = ?, username = ?, email = ?, role = ?, profile = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                  [$form['fullname'], $form['username'], $form['email'], $form['role'], $profile, $id]);
                if ($password !== '') {
                    q('UPDATE users SET password_hash = ? WHERE id = ?',
                      [password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]), $id]);
                }
                $userId = $id;
            } else {
                q('INSERT INTO users (fullname, username, email, password_hash, role, profile) VALUES (?, ?, ?, ?, ?, ?)',
                  [$form['fullname'], $form['username'], $form['email'],
                   password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]), $form['role'], $profile]);
                $userId = (int) $pdo->lastInsertId();
            }

            // Customers have a wallet; create it or set its balance.
            if ($form['role'] === 'user') {
                q('INSERT INTO wallets (user_id, balance, currency) VALUES (?, ?, ?)
                   ON DUPLICATE KEY UPDATE balance = VALUES(balance)', [$userId, round((float) $form['balance'], 2), 'USD']);
            }
            $pdo->commit();
        } catch (Throwable $error) {
            $pdo->rollBack();
            throw $error;
        }
        flash('ok', ($existing ? 'Saved ' : 'Added ') . $form['fullname'] . '.');
        redirect('users.php');
    }
}

admin_header($existing ? 'Edit user' : 'Add user', 'users');
?>
<div class="page-head">
  <div><h1><?= $existing ? 'Edit user' : 'Add user' ?></h1></div>
  <div class="actions"><a class="btn" href="users.php">Back to users</a></div>
</div>

<?php if ($errors): ?>
  <div class="flash bad">Please fix the following and save again:
    <ul><?php foreach ($errors as $error): ?><li><?= e($error) ?></li><?php endforeach; ?></ul></div>
<?php endif; ?>

<form method="post" autocomplete="off">
  <?= csrf_field() ?>
  <div class="card">
    <div class="grid">
      <div class="col-6"><label for="fullname">Full name</label>
        <input type="text" id="fullname" name="fullname" value="<?= e($form['fullname']) ?>" maxlength="120" required></div>
      <div class="col-6"><label for="username">Username</label>
        <input type="text" id="username" name="username" value="<?= e($form['username']) ?>" maxlength="60" required></div>
      <div class="col-6"><label for="email">Email</label>
        <input type="email" id="email" name="email" value="<?= e($form['email']) ?>" maxlength="190" required></div>
      <div class="col-6"><label for="password">Password</label>
        <input type="password" id="password" name="password" minlength="8" autocomplete="new-password" <?= $existing ? '' : 'required' ?>>
        <div class="hint"><?= $existing ? 'Leave empty to keep the current password.' : 'At least 8 characters.' ?></div></div>
      <div class="col-6"><label for="role">Role</label>
        <select id="role" name="role" <?= $isSelf ? 'disabled' : '' ?>>
          <option value="user" <?= $form['role'] === 'user' ? 'selected' : '' ?>>Customer (uses the app)</option>
          <option value="admin" <?= $form['role'] === 'admin' ? 'selected' : '' ?>>Admin (uses this site)</option>
        </select>
        <?php if ($isSelf): ?><div class="hint">You cannot change your own role.</div><?php endif; ?></div>
      <div class="col-6"><label for="balance">Wallet balance (USD)</label>
        <input type="number" id="balance" name="balance" value="<?= e($form['balance']) ?>" min="0" step="0.01">
        <div class="hint">Customers pay for orders from this wallet. Not used for admins.</div></div>
      <div class="col-12"><label for="profile">Profile picture address</label>
        <input type="text" id="profile" name="profile" value="<?= e($form['profile']) ?>" placeholder="https://example.com/photo.jpg"></div>
    </div>
  </div>
  <div class="form-actions">
    <button class="btn primary" type="submit"><?= $existing ? 'Save changes' : 'Add user' ?></button>
    <a href="users.php">Cancel</a>
  </div>
</form>
<?php admin_footer();
