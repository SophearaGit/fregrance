<?php
/**
 * /auth endpoints: register, login and Google sign-in. They reply with { message, token }.
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

    if ($username === '' || $fullname === '' || $password === '' || $email === '') {
        json_response(400, ['message' => 'Please fill in every field.']);
    }
    if (!is_valid_email($email)) {
        json_response(409, ['message' => 'That email address does not look right.']);
    }
    if (!preg_match('/^[a-z0-9_.]{3,30}$/', $username)) {
        json_response(409, ['message' => 'Username must be 3 to 30 letters, numbers, dots or underscores.']);
    }
    if (q('SELECT 1 FROM users WHERE email = ?', [$email])->fetchColumn()) {
        json_response(409, ['message' => 'This email already has an account. Log in instead.']);
    }
    if (q('SELECT 1 FROM users WHERE username = ?', [$username])->fetchColumn()) {
        json_response(409, ['message' => 'That username is taken. Try another one.']);
    }
    if (!is_valid_password($password)) {
        json_response(409, ['message' => 'Password needs at least 8 characters, with a letter, a number and a symbol.']);
    }
    $fullname = mb_substr($fullname, 0, 120);

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

    $user = q('SELECT id, username, role, password_hash FROM users WHERE email = ?', [strtolower($email)])->fetch();
    if (!$user) {
        json_response(401, ['message' => 'Invalid email or password']);
    }
    if (!password_verify($password, $user['password_hash'])) {
        json_response(401, ['message' => 'Invalid password']);
    }

    json_response(200, ['message' => 'User login successful', 'token' => jwt_create($user)]);
}

// ---------------------------------------------------------------------------
// Google sign-in
// ---------------------------------------------------------------------------

/** The Web OAuth client ID from google-config.php, or '' when not set up. */
function google_client_id(): string
{
    $file = APP_ROOT . '/google-config.php';
    $config = is_file($file) ? require $file : [];
    return is_array($config) ? trim((string) ($config['web_client_id'] ?? '')) : '';
}

/** GET /auth/google/config  Tells the app which Google client to sign in with. */
function api_auth_google_config(): void
{
    json_response(200, ['message' => 'Google sign-in settings', 'data' => ['clientId' => google_client_id()]]);
}

/**
 * Ask Google whether an ID token is genuine. Returns its claims, or null.
 * Google checks the signature and expiry; we check it was made for our app.
 */
function google_verify_id_token(string $idToken, string $clientId): ?array
{
    $url = 'https://oauth2.googleapis.com/tokeninfo?id_token=' . rawurlencode($idToken);
    $body = null;

    if (function_exists('curl_init')) {
        $curl = curl_init($url);
        curl_setopt_array($curl, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 10]);
        // Laragon's PHP may not know where the trusted certificates are; point it at Laragon's copy.
        foreach ([(string) ini_get('curl.cainfo'), 'C:/laragon/etc/ssl/cacert.pem',
                  dirname((string) ($_SERVER['DOCUMENT_ROOT'] ?? '')) . '/etc/ssl/cacert.pem'] as $ca) {
            if ($ca !== '' && is_file($ca)) {
                curl_setopt($curl, CURLOPT_CAINFO, $ca);
                break;
            }
        }
        $result = curl_exec($curl);
        $status = (int) curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $curlError = curl_error($curl);
        curl_close($curl);
        if ($result === false) {
            throw new RuntimeException('Could not reach Google to check the sign-in: ' . $curlError);
        }
        $body = $status === 200 ? $result : null;
    } else {
        $result = @file_get_contents($url);
        $body = $result === false ? null : $result;
    }

    $claims = $body === null ? null : json_decode($body, true);
    if (!is_array($claims)) {
        return null;
    }
    $issuerOk = in_array($claims['iss'] ?? '', ['accounts.google.com', 'https://accounts.google.com'], true);
    $verified = ($claims['email_verified'] ?? '') === 'true' || ($claims['email_verified'] ?? false) === true;
    if (($claims['aud'] ?? '') !== $clientId || !$issuerOk || !$verified
        || (int) ($claims['exp'] ?? 0) < time() || !is_valid_email((string) ($claims['email'] ?? ''))) {
        return null;
    }
    return $claims;
}

/**
 * POST /auth/google  { idToken }
 * Signs in the customer with this Google email, creating the account the first time.
 */
function api_auth_google(): void
{
    $clientId = google_client_id();
    if ($clientId === '') {
        json_response(503, ['message' => 'Google sign-in is not set up yet. Add the client ID to fragrance_backend/google-config.php.']);
    }
    $idToken = body_string(json_body(), 'idToken');
    if ($idToken === '') {
        json_response(400, ['message' => 'Missing Google sign-in token.']);
    }

    $claims = google_verify_id_token($idToken, $clientId);
    if ($claims === null) {
        json_response(401, ['message' => 'Google sign-in could not be verified. Please try again.']);
    }

    $email = strtolower((string) $claims['email']);
    $user = q('SELECT id, username, role FROM users WHERE email = ?', [$email])->fetch();

    if ($user && $user['role'] !== 'user') {
        json_response(403, ['message' => 'This email belongs to an admin account. Admins use the admin site.']);
    }

    if (!$user) {
        // First Google sign-in: create the customer. Name and photo come from Google.
        $base = substr(strtolower(preg_replace('/[^A-Za-z0-9]/', '', strstr($email, '@', true))), 0, 50) ?: 'user';
        $username = $base;
        for ($n = 2; q('SELECT 1 FROM users WHERE username = ?', [$username])->fetchColumn(); $n++) {
            $username = $base . $n;
        }
        $fullname = trim((string) ($claims['name'] ?? '')) ?: $base;
        $picture = trim((string) ($claims['picture'] ?? ''));

        $pdo = db();
        $pdo->beginTransaction();
        try {
            q('INSERT INTO users (fullname, username, email, password_hash, role, profile) VALUES (?, ?, ?, ?, ?, ?)', [
                mb_substr($fullname, 0, 100), $username, $email,
                // A random password nobody knows: this account signs in with Google.
                password_hash(bin2hex(random_bytes(24)), PASSWORD_BCRYPT, ['cost' => 12]),
                'user', $picture === '' ? null : $picture,
            ]);
            $userId = (int) $pdo->lastInsertId();
            q('INSERT INTO wallets (user_id, balance, currency) VALUES (?, ?, ?)',
              [$userId, (float) (app_config()['new_wallet_balance'] ?? 0), 'USD']);
            $pdo->commit();
        } catch (Throwable $error) {
            $pdo->rollBack();
            throw $error;
        }
        $user = ['id' => $userId, 'username' => $username, 'role' => 'user'];
    }

    json_response(200, ['message' => 'User login successful', 'token' => jwt_create($user)]);
}

