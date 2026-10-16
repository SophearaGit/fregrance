<?php
/** Admin sign-in. Only users with role "admin" can enter. */
declare(strict_types=1);
require __DIR__ . '/_init.php';

if (current_admin() !== null) {
    redirect('index.php');
}

$error = null;
$email = '';

if (is_post()) {
    verify_csrf();
    $email = trim((string) ($_POST['email'] ?? ''));
    $password = (string) ($_POST['password'] ?? '');

    $user = q("SELECT id, password_hash FROM users WHERE email = ? AND role = 'admin'", [$email])->fetch();
    if ($user && password_verify($password, $user['password_hash'])) {
        session_regenerate_id(true);
        $_SESSION['admin_id'] = (int) $user['id'];
        redirect('index.php');
    }
    usleep(400000);   // slow down password guessing
    $error = 'That email and password do not match an admin account.';
}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sign in · Fragrance admin</title>
<link rel="stylesheet" href="assets/admin.css?v=<?= filemtime(__DIR__ . '/assets/admin.css') ?>">
</head>
<body>
<div class="center-page narrow">
  <div class="logo">Fragrance <span>admin</span></div>
  <?php if ($error): ?><div class="flash bad"><?= e($error) ?></div><?php endif; ?>
  <form method="post" class="card">
    <?= csrf_field() ?>
    <div class="grid">
      <div class="col-12"><label for="email">Email</label>
        <input type="email" id="email" name="email" value="<?= e($email) ?>" required autofocus></div>
      <div class="col-12"><label for="password">Password</label>
        <input type="password" id="password" name="password" required></div>
      <div class="col-12"><button class="btn primary" type="submit">Sign in</button></div>
    </div>
  </form>
</div>
</body>
</html>
