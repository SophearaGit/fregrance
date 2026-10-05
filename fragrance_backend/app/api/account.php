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

    json_response(200, [
        'message' => 'User found.',
        'data'    => [
            'id'        => (string) $user['id'],
            'fullname'  => $user['fullname'],
            'username'  => $user['username'],
            'email'     => $user['email'],
            'role'      => $user['role'],
            'profile'   => public_image_url($user['profile']),
            'createdAt' => iso_date($user['created_at']),
            'updatedAt' => iso_date($user['updated_at']),
        ],
    ]);
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

/** GET /address : the customer's addresses, default one first. */
function api_address_list(): void
{
    $auth = require_auth('user');
    $userId = (int) $auth['id'];

    if (!q('SELECT 1 FROM users WHERE id = ?', [$userId])->fetchColumn()) {
        json_response(404, ['message' => 'User not found.']);
    }
    $rows = q('SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC, created_at DESC, id DESC',
              [$userId])->fetchAll();
    if ($rows === []) {
        json_response(404, ['message' => 'No addresses found for this user.']);
    }

    json_response(200, [
        'message' => 'User address retrieved successfully.',
        'data'    => array_map('address_json', $rows),
    ]);
}

/** POST /address/add  { name, phone, addressLine, city, province, postalCode, isDefault? } */
function api_address_create(): void
{
    $auth = require_auth('user');
    $userId = (int) $auth['id'];
    $body = json_body();

    if (!q('SELECT 1 FROM users WHERE id = ?', [$userId])->fetchColumn()) {
        json_response(404, ['message' => 'User not found.', 'data' => null]);
    }

    $fields = [];
    foreach (['name', 'phone', 'addressLine', 'city', 'province', 'postalCode'] as $key) {
        $fields[$key] = body_string($body, $key);
        if ($fields[$key] === '') {
            json_response(400, ['message' => 'All address fields are required.', 'data' => null]);
        }
    }
    if (q('SELECT 1 FROM addresses WHERE user_id = ? AND name = ?', [$userId, $fields['name']])->fetchColumn()) {
        json_response(400, ['message' => 'An address with this name already exists.', 'data' => null]);
    }

    $isFirst = (int) q('SELECT COUNT(*) FROM addresses WHERE user_id = ?', [$userId])->fetchColumn() === 0;
    $isDefault = $isFirst || (is_array($body) && ($body['isDefault'] ?? false) === true);

    $pdo = db();
    $pdo->beginTransaction();
    try {
        if ($isDefault) {
            q('UPDATE addresses SET is_default = 0 WHERE user_id = ?', [$userId]);
        }
        q('INSERT INTO addresses (user_id, name, phone, address_line, city, province, postal_code, is_default)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [
            $userId, $fields['name'], $fields['phone'], $fields['addressLine'], $fields['city'],
            $fields['province'], $fields['postalCode'], $isDefault ? 1 : 0,
        ]);
        $id = (int) $pdo->lastInsertId();
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }

    $row = q('SELECT * FROM addresses WHERE id = ?', [$id])->fetch();
    json_response(201, ['message' => 'Address created successfully.', 'data' => address_json($row)]);
}
