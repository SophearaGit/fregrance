<?php
/**
 * Endpoints about the signed-in user: profile, wallet and delivery addresses.
 */
declare(strict_types=1);

/** GET /user : the signed-in user's profile. */
function api_user_me(): void
{
    $auth = require_auth();
    $user = q('SELECT * FROM users WHERE id = ?', [(int) $auth['id']])->fetch();
    if (!$user) {
        json_response(404, ['message' => 'User not found.', 'data' => null]);
    }

    json_response(200, ['message' => 'User found.', 'data' => user_json($user)]);
}

/** A user row in the shape the app reads. */
function user_json(array $user): array
{
    return [
        'id'        => (string) $user['id'],
        'fullname'  => $user['fullname'],
        'username'  => $user['username'],
        'email'     => $user['email'],
        'role'      => $user['role'],
        'profile'   => public_image_url($user['profile']),
        'createdAt' => iso_date($user['created_at']),
        'updatedAt' => iso_date($user['updated_at']),
    ];
}

/** The signed-in user's row, or a 404 reply. */
function current_user_row(): array
{
    $auth = require_auth();
    $user = q('SELECT * FROM users WHERE id = ?', [(int) $auth['id']])->fetch();
    if (!$user) {
        json_response(404, ['message' => 'User not found.', 'data' => null]);
    }
    return $user;
}

/** POST /user  { fullname, username, email }  Edit your own details. */
function api_user_update(): void
{
    $user = current_user_row();
    $body = json_body();
    $fullname = mb_substr(body_string($body, 'fullname'), 0, 120);
    $username = strtolower(body_string($body, 'username'));
    $email = strtolower(body_string($body, 'email'));

    if ($fullname === '' || $username === '' || $email === '') {
        json_response(400, ['message' => 'Please fill in your name, username and email.']);
    }
    if (!preg_match('/^[a-z0-9_.]{3,30}$/', $username)) {
        json_response(409, ['message' => 'Username must be 3 to 30 letters, numbers, dots or underscores.']);
    }
    if (!is_valid_email($email)) {
        json_response(409, ['message' => 'That email address does not look right.']);
    }
    if (q('SELECT 1 FROM users WHERE username = ? AND id <> ?', [$username, $user['id']])->fetchColumn()) {
        json_response(409, ['message' => 'That username is taken. Try another one.']);
    }
    if (q('SELECT 1 FROM users WHERE email = ? AND id <> ?', [$email, $user['id']])->fetchColumn()) {
        json_response(409, ['message' => 'Another account already uses this email.']);
    }

    q('UPDATE users SET fullname = ?, username = ?, email = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [$fullname, $username, $email, $user['id']]);
    $fresh = q('SELECT * FROM users WHERE id = ?', [$user['id']])->fetch();
    json_response(200, ['message' => 'Profile saved.', 'data' => user_json($fresh)]);
}

/** POST /user/avatar  multipart "avatar" file  Change your profile photo. */
function api_user_avatar(): void
{
    $user = current_user_row();
    if (!isset($_FILES['avatar'])) {
        json_response(400, ['message' => 'Choose a photo to upload.']);
    }
    try {
        $stored = store_uploaded_image($_FILES['avatar']);
    } catch (RuntimeException $error) {
        json_response(400, ['message' => $error->getMessage()]);
    }

    q('UPDATE users SET profile = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [$stored, $user['id']]);
    // Remove the old photo file if it was uploaded here and nothing else uses it.
    $old = (string) ($user['profile'] ?? '');
    if (str_starts_with($old, 'uploads/')
        && !q('SELECT 1 FROM users WHERE profile = ?', [$old])->fetchColumn()) {
        delete_unused_uploads([$old]);
    }

    $fresh = q('SELECT * FROM users WHERE id = ?', [$user['id']])->fetch();
    json_response(200, ['message' => 'Photo updated.', 'data' => user_json($fresh)]);
}

/** POST /user/password  { currentPassword, newPassword }  Change your password. */
function api_user_password(): void
{
    $user = current_user_row();
    $body = json_body();
    $current = body_string($body, 'currentPassword', false);
    $new = body_string($body, 'newPassword', false);

    if (!password_verify($current, $user['password_hash'])) {
        json_response(401, ['message' => 'Your current password is not right.']);
    }
    if (!is_valid_password($new)) {
        json_response(409, ['message' => 'New password needs at least 8 characters, with a letter, a number and a symbol.']);
    }

    q('UPDATE users SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [password_hash($new, PASSWORD_BCRYPT, ['cost' => 12]), $user['id']]);
    json_response(200, ['message' => 'Password changed.']);
}

/** GET /wallet : the signed-in customer's wallet. */
function api_wallet(): void
{
    $auth = require_auth('user');
    $wallet = q('SELECT * FROM wallets WHERE user_id = ?', [(int) $auth['id']])->fetch();
    if (!$wallet) {
        json_response(404, ['message' => 'Wallet not found', 'data' => null]);
    }

    json_response(200, [
        'message' => 'Wallet found.',
        'data'    => [
            'userId'    => (string) $wallet['user_id'],
            'balance'   => json_number($wallet['balance']),
            'currency'  => $wallet['currency'],
            'createdAt' => iso_date($wallet['created_at']),
            'updatedAt' => iso_date($wallet['updated_at']),
            'id'        => (string) $wallet['id'],
        ],
    ]);
}

function address_json(array $row): array
{
    return [
        'userId'      => (string) $row['user_id'],
        'label'       => (string) ($row['label'] ?? ''),
        'name'        => $row['name'],
        'phone'       => $row['phone'],
        'addressLine' => $row['address_line'],
        'city'        => $row['city'],
        'province'    => $row['province'],
        'postalCode'  => $row['postal_code'],
        'isDefault'   => (bool) $row['is_default'],
        'createdAt'   => iso_date($row['created_at']),
        'updatedAt'   => iso_date($row['updated_at']),
        'id'          => (string) $row['id'],
    ];
}

/** Databases made before addresses had a label ("Home", "Work") get the column once. */
function address_ensure_schema(): void
{
    static $done = false;
    if ($done) {
        return;
    }
    $has = q("SELECT 1 FROM information_schema.COLUMNS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'addresses' AND COLUMN_NAME = 'label'")->fetchColumn();
    if (!$has) {
        db()->exec("ALTER TABLE addresses ADD COLUMN label VARCHAR(40) NOT NULL DEFAULT '' AFTER user_id");
    }
    $done = true;
}

/** The signed-in customer's id (404 when the account was deleted). */
function address_user_id(): int
{
    address_ensure_schema();
    $auth = require_auth('user');
    $userId = (int) $auth['id'];
    if (!q('SELECT 1 FROM users WHERE id = ?', [$userId])->fetchColumn()) {
        json_response(404, ['message' => 'User not found.', 'data' => null]);
    }
    return $userId;
}

/** One of the customer's own addresses, or a 404 reply. */
function owned_address(int $userId, string $id): array
{
    $row = q('SELECT * FROM addresses WHERE id = ? AND user_id = ?', [(int) $id, $userId])->fetch();
    if (!$row) {
        json_response(404, ['message' => 'Address not found.', 'data' => null]);
    }
    return $row;
}

/**
 * Read and check the address fields from the request body.
 * Label (e.g. "Home"), receiver name and postal code are optional; the rest are required.
 */
function address_input(mixed $body): array
{
    $fields = [
        'label'       => mb_substr(body_string($body, 'label'), 0, 40),
        'name'        => mb_substr(body_string($body, 'name'), 0, 120),
        'phone'       => mb_substr(body_string($body, 'phone'), 0, 40),
        'addressLine' => mb_substr(body_string($body, 'addressLine'), 0, 255),
        'city'        => mb_substr(body_string($body, 'city'), 0, 120),
        'province'    => mb_substr(body_string($body, 'province'), 0, 120),
        'postalCode'  => mb_substr(body_string($body, 'postalCode'), 0, 20),
    ];
    $missing = [];
    foreach (['name' => 'receiver name', 'phone' => 'phone number', 'addressLine' => 'street address',
              'city' => 'city / district', 'province' => 'province'] as $key => $label) {
        if ($fields[$key] === '') {
            $missing[] = $label;
        }
    }
    if ($missing) {
        json_response(400, ['message' => 'Please fill in the ' . implode(', ', $missing) . '.', 'data' => null]);
    }
    if (!preg_match('/^[0-9+()\s-]{6,20}$/', $fields['phone'])) {
        json_response(400, ['message' => 'That phone number does not look right.', 'data' => null]);
    }
    return $fields;
}

/** Make sure the customer has exactly one default address when they have any. */
function address_fix_default(int $userId): void
{
    $hasDefault = q('SELECT 1 FROM addresses WHERE user_id = ? AND is_default = 1', [$userId])->fetchColumn();
    if (!$hasDefault) {
        q('UPDATE addresses SET is_default = 1 WHERE user_id = ? ORDER BY created_at DESC, id DESC LIMIT 1', [$userId]);
    }
}

/** GET /address : the customer's addresses, default one first (an empty list when there are none). */
function api_address_list(): void
{
    $userId = address_user_id();
    $rows = q('SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC, created_at DESC, id DESC',
              [$userId])->fetchAll();

    json_response(200, [
        'message' => $rows ? 'User address retrieved successfully.' : 'No addresses yet.',
        'data'    => array_map('address_json', $rows),
    ]);
}

/** POST /address/add  { label?, name, phone, addressLine, city, province, postalCode?, isDefault? } */
function api_address_create(): void
{
    $userId = address_user_id();
    $body = json_body();
    $fields = address_input($body);

    $count = (int) q('SELECT COUNT(*) FROM addresses WHERE user_id = ?', [$userId])->fetchColumn();
    if ($count >= 20) {
        json_response(400, ['message' => 'You can save up to 20 addresses. Delete one first.', 'data' => null]);
    }
    $isDefault = $count === 0 || (is_array($body) && ($body['isDefault'] ?? false) === true);

    $pdo = db();
    $pdo->beginTransaction();
    try {
        if ($isDefault) {
            q('UPDATE addresses SET is_default = 0 WHERE user_id = ?', [$userId]);
        }
        q('INSERT INTO addresses (user_id, label, name, phone, address_line, city, province, postal_code, is_default)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
            $userId, $fields['label'], $fields['name'], $fields['phone'], $fields['addressLine'],
            $fields['city'], $fields['province'], $fields['postalCode'], $isDefault ? 1 : 0,
        ]);
        $id = (int) $pdo->lastInsertId();
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }

    $row = q('SELECT * FROM addresses WHERE id = ?', [$id])->fetch();
    json_response(201, ['message' => 'Address saved.', 'data' => address_json($row)]);
}

/** POST /address/{id}/update  same fields as add */
function api_address_update(string $id): void
{
    $userId = address_user_id();
    $row = owned_address($userId, $id);
    $body = json_body();
    $fields = address_input($body);
    $makeDefault = is_array($body) && ($body['isDefault'] ?? false) === true;

    $pdo = db();
    $pdo->beginTransaction();
    try {
        if ($makeDefault) {
            q('UPDATE addresses SET is_default = 0 WHERE user_id = ?', [$userId]);
        }
        q('UPDATE addresses SET label = ?, name = ?, phone = ?, address_line = ?, city = ?, province = ?,
                  postal_code = ?, is_default = ?
            WHERE id = ?', [
            $fields['label'], $fields['name'], $fields['phone'], $fields['addressLine'], $fields['city'],
            $fields['province'], $fields['postalCode'], ($makeDefault || $row['is_default']) ? 1 : 0, $row['id'],
        ]);
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }

    $fresh = q('SELECT * FROM addresses WHERE id = ?', [$row['id']])->fetch();
    json_response(200, ['message' => 'Address saved.', 'data' => address_json($fresh)]);
}

/** POST /address/{id}/default  Use this address by default. */
function api_address_set_default(string $id): void
{
    $userId = address_user_id();
    $row = owned_address($userId, $id);
    $pdo = db();
    $pdo->beginTransaction();
    try {
        q('UPDATE addresses SET is_default = 0 WHERE user_id = ?', [$userId]);
        q('UPDATE addresses SET is_default = 1 WHERE id = ?', [$row['id']]);
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }
    $fresh = q('SELECT * FROM addresses WHERE id = ?', [$row['id']])->fetch();
    json_response(200, ['message' => 'Default address changed.', 'data' => address_json($fresh)]);
}

/** POST /address/{id}/delete  The next newest address becomes the default if needed. */
function api_address_delete(string $id): void
{
    $userId = address_user_id();
    $row = owned_address($userId, $id);
    q('DELETE FROM addresses WHERE id = ?', [$row['id']]);
    address_fix_default($userId);
    json_response(200, ['message' => 'Address deleted.', 'data' => ['id' => (string) $row['id']]]);
}
