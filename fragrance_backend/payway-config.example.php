<?php
/**
 * ABA PayWay settings. Copy this file to payway-config.php and fill it in.
 * payway-config.php is in .gitignore, so your keys never go to GitHub.
 *
 * merchant_id / api_key : from ABA (the sandbox ones for testing).
 * api_url               : https://checkout-sandbox.payway.com.kh for testing,
 *                         https://checkout.payway.com.kh for real payments.
 * domain                : a website on this merchant's PayWay whitelist, e.g. https://myshop.com.
 *                         PayWay rejects purchases from other addresses (error 6).
 */
return [
    'merchant_id' => '',
    'api_key'     => '',
    'api_url'     => 'https://checkout-sandbox.payway.com.kh',
    'domain'      => '',
];
