<?php
// Settings written by install.php. Delete this file to run the installer again.
// db: MySQL connection.  jwt_secret: signs app login tokens (keep private).
// jwt_expires_days: how long an app login lasts.
// new_wallet_balance: wallet balance given to a customer who registers.
return array (
  'db' => 
  array (
    'host' => '127.0.0.1',
    'port' => 3306,
    'name' => 'fragrance_db',
    'user' => 'root',
    'pass' => '',
  ),
  'jwt_secret' => '21fa29ee3352b325a28076f47841b5deef52e29301cacf98c29a65651811973e',
  'jwt_expires_days' => 7,
  'new_wallet_balance' => 0,
);
