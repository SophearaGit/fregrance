<?php
/** Customers and admins: list and delete. */
declare(strict_types=1);
require __DIR__ . '/_init.php';
$admin = require_admin();

if (is_post()) {
    verify_csrf();
    $id = (int) ($_POST['delete_id'] ?? 0);
    $user = q('SELECT fullname FROM users WHERE id = ?', [$id])->fetch();
    if ($id === (int) $admin['id']) {
        flash('bad', 'You cannot delete the account you are signed in with.');
    } elseif ($user) {
        q('DELETE FROM users WHERE id = ?', [$id]);   // their wallet, addresses and orders are removed too
        flash('ok', 'Deleted ' . $user['fullname'] . '.');
    }
    redirect('users.php');
}

$search = trim((string) ($_GET['q'] ?? ''));
$where = '1 = 1';
$params = [];
if ($search !== '') {
    $where = '(u.fullname LIKE ? OR u.username LIKE ? OR u.email LIKE ?)';
    $like = '%' . like_escape($search) . '%';
    $params = [$like, $like, $like];
}

$users = q(
    "SELECT u.*, w.balance, w.currency,
            (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) AS order_count
       FROM users u LEFT JOIN wallets w ON w.user_id = u.id
      WHERE $where ORDER BY u.role = 'admin' DESC, u.id DESC",
    $params
)->fetchAll();

admin_header('Users', 'users');
?>
<div class="page-head">
  <div><h1>Users</h1><div class="muted">Customers sign in to the app; admins sign in here.</div></div>
  <div class="actions"><a class="btn primary" href="user_form.php">Add user</a></div>
</div>

<form method="get" class="toolbar">
  <input type="search" name="q" value="<?= e($search) ?>" placeholder="Search name, username or email">
  <button class="btn" type="submit">Search</button>
  <?php if ($search !== ''): ?><a href="users.php">Clear</a><?php endif; ?>
</form>

<div class="card flush">
  <?php if (!$users): ?>
    <div class="empty">No users match.</div>
  <?php else: ?>
  <div class="table-wrap"><table>
    <thead><tr><th>Name</th><th>Email</th><th>Role</th><th class="num">Wallet</th><th class="num">Orders</th><th>Joined</th><th></th></tr></thead>
    <tbody>
    <?php foreach ($users as $u): ?>
      <tr>
        <td><a href="user_form.php?id=<?= (int) $u['id'] ?>"><?= e($u['fullname']) ?></a><div class="muted small">@<?= e($u['username']) ?></div></td>
        <td><?= e($u['email']) ?></td>
        <td><?= $u['role'] === 'admin' ? '<span class="badge accent">Admin</span>' : '<span class="badge">Customer</span>' ?></td>
        <td class="num"><?= $u['balance'] === null ? '<span class="muted">none</span>' : money($u['balance'], $u['currency']) ?></td>
        <td class="num"><?= (int) $u['order_count'] ?></td>
        <td class="nowrap"><?= show_date($u['created_at']) ?></td>
        <td class="actions">
          <a class="btn small" href="user_form.php?id=<?= (int) $u['id'] ?>">Edit</a>
          <?php if ((int) $u['id'] !== (int) $admin['id']): ?>
          <form method="post" data-confirm="Delete <?= e($u['fullname']) ?>? Their wallet, addresses and <?= (int) $u['order_count'] ?> order(s) are deleted too.">
            <?= csrf_field() ?>
            <input type="hidden" name="delete_id" value="<?= (int) $u['id'] ?>">
            <button class="btn small danger" type="submit">Delete</button>
          </form>
          <?php endif; ?>
        </td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table></div>
  <?php endif; ?>
</div>
<?php admin_footer();
