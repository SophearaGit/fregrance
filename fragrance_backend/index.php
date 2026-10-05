<?php
// Opening the backend folder goes to the admin site, or to the installer the first time.
declare(strict_types=1);
require __DIR__ . '/app/bootstrap.php';
header('Location: ' . (app_config() === null ? 'install.php' : 'admin/'));
