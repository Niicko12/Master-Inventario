<?php
session_start();
require_once 'config.php';

if (!isset($_SESSION['temp_user_id']) && !isset($_SESSION['user_id'])) {
    echo "error_session";
    exit;
}

if (!isset($_SESSION['verification_code'])) {
    echo "error_no_code";
    exit;
}

$enteredCode = trim($_POST['verificationCode'] ?? '');
$storedCode  = $_SESSION['verification_code'];

if ($enteredCode === $storedCode) {
    if (isset($_SESSION['temp_user_id'])) {
        $_SESSION['user_id']   = $_SESSION['temp_user_id'];
        $_SESSION['user_role'] = $_SESSION['temp_user_role'];
        $_SESSION['email']     = $_SESSION['temp_email'];
        $_SESSION['nombre']    = $_SESSION['temp_nombre'];
        unset($_SESSION['temp_user_id'], $_SESSION['temp_user_role'],
              $_SESSION['temp_email'],   $_SESSION['temp_nombre']);
    }
    unset($_SESSION['verification_code'], $_SESSION['2fa_email_sent']);
    echo "success";
} else {
    echo "error_mismatch";
}
