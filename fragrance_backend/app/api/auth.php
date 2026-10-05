<?php
/**
 * /auth endpoints: register and login. Both reply with { message, token }.
 */
declare(strict_types=1);

/** At least 8 characters with a letter, a number and a symbol (same rule as the old API). */
function is_valid_password(string $password): bool
{
    return strlen($password) >= 8
        && preg_match('/[A-Za-z]/', $password)
        && preg_match('/\d/', $password)
        && preg_match('/[^A-Za-z0-9]/', $password);
}

function is_valid_email(string $email): bool
{
    return (bool) preg_match('/^[^\s@]+@[^\s@]+\.[^\s@]+$/', $email);
}

/** A string field of the JSON body, trimmed, or '' when missing. */
function body_string(mixed $body, string $key, bool $trim = true): string
{
    $value = is_array($body) && is_string($body[$key] ?? null) ? $body[$key] : '';
    return $trim ? trim($value) : $value;
}

/** POST /auth/register  { fullname, username, email, password, profile? } */
function api_auth_register(): void
{
    $body = json_body();
    $email = strtolower(body_string($body, 'email'));
    $username = strtolower(body_string($body, 'username'));
    $fullname = body_string($body, 'fullname');
    $password = body_string($body, 'password', false);
    $profile = body_string($body, 'profile');

    if ($email === '' || !is_valid_email($email)) {
        json_response(409, ['message' => 'Email invalid.']);
    }
    if ($username === '' || $fullname === '' || $password === '') {
        json_response(400, ['message' => 'Missing required fields.']);
    }
    if (q('SELECT 1 FROM users WHERE email = ? OR username = ?', [$email, $username])->fetchColumn()) {
        json_response(409, ['message' => 'Email or username already registered']);
    }
    if (!is_valid_password($password)) {
        json_response(409, ['message' => 'Invalid password']);
    }

    $pdo = db();
    $pdo->beginTransaction();
    try {
        q('INSERT INTO users (fullname, username, email, password_hash, role, profile) VALUES (?, ?, ?, ?, ?, ?)', [
            $fullname, $username, $email,
            password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]),
            'user', $profile === '' ? null : $profile,
        ]);
        $userId = (int) $pdo->lastInsertId();
        // Every new customer gets a wallet so they can place orders.
        q('INSERT INTO wallets (user_id, balance, currency) VALUES (?, ?, ?)',
          [$userId, (float) (app_config()['new_wallet_balance'] ?? 0), 'USD']);
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }

    $token = jwt_create(['id' => $userId, 'username' => $username, 'role' => 'user']);
    json_response(201, ['message' => 'User registered successfully', 'token' => $token]);
}

/** POST /auth/login  { email, password } */
function api_auth_login(): void
{
    $body = json_body();
    $email = body_string($body, 'email');
    $password = body_string($body, 'password', false);

    if ($email === '' || $password === '') {
        json_response(400, ['message' => 'Email and password are required.']);
    }

    $user = q('SELECT id, username, role, password_hash FROM users WHERE email = ?', [$email])->fetch();
    if (!$user) {
        json_response(401, ['message' => 'Invalid email or password']);
    }
    if (!password_verify($password, $user['password_hash'])) {
        json_response(401, ['message' => 'Invalid password']);
    }

    json_response(200, ['message' => 'User login successful', 'token' => jwt_create($user)]);
}
