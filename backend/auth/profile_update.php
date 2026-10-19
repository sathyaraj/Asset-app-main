<?php

require_once '../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// ----------------------------------------
// Handle OPTIONS
// ----------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ----------------------------------------
// Only PUT / POST allowed
// ----------------------------------------
if (
    $_SERVER['REQUEST_METHOD'] !== 'PUT' &&
    $_SERVER['REQUEST_METHOD'] !== 'POST'
) {
    http_response_code(405);

    echo json_encode([
        "success" => false,
        "message" => "Method not allowed."
    ]);

    exit;
}

// ----------------------------------------
// Authenticate JWT
// ----------------------------------------
$decoded = authenticate();

// ----------------------------------------
// Get user ID from JWT
// ----------------------------------------
$userId = isset($decoded->user_id)
    ? (int) $decoded->user_id
    : 0;

if ($userId <= 0) {
    http_response_code(401);

    echo json_encode([
        "success" => false,
        "message" => "Invalid user information in token."
    ]);

    exit;
}

// ----------------------------------------
// Read JSON request
// ----------------------------------------
$input = json_decode(
    file_get_contents("php://input"),
    true
);

if (!is_array($input)) {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid request data."
    ]);

    exit;
}

// ----------------------------------------
// Get fields
// ----------------------------------------
$phone = isset($input['phone'])
    ? trim($input['phone'])
    : null;

$email = isset($input['email'])
    ? trim($input['email'])
    : null;

$location = isset($input['location'])
    ? trim($input['location'])
    : null;

$role = isset($input['role'])
    ? strtolower(trim($input['role']))
    : null;

// ----------------------------------------
// Validate email
// ----------------------------------------
if ($email === null || $email === '') {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Email is required."
    ]);

    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid email address."
    ]);

    exit;
}

// ----------------------------------------
// Validate role
// ----------------------------------------
$allowedRoles = [
    'admin' => 'Admin',
    'manager' => 'Manager',
    'technician' => 'Technician'
];

if ($role === null || !isset($allowedRoles[$role])) {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid role."
    ]);

    exit;
}

$dbRole = $allowedRoles[$role];

// ----------------------------------------
// Check user exists
// ----------------------------------------
try {

    $checkUserSql = "
        SELECT
            id,
            login_access
        FROM emp_users
        WHERE id = :id
        LIMIT 1
    ";

    $checkStmt = $conn->prepare($checkUserSql);

    $checkStmt->execute([
        ':id' => $userId
    ]);

    $existingUser = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$existingUser) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "User not found."
        ]);

        exit;
    }

    // ----------------------------------------
    // Login access check
    // ----------------------------------------
    if ((int)$existingUser['login_access'] !== 1) {
        http_response_code(403);

        echo json_encode([
            "success" => false,
            "message" => "Login access has been disabled."
        ]);

        exit;
    }

    // ----------------------------------------
    // Check duplicate email
    // ----------------------------------------
    $emailCheckSql = "
        SELECT id
        FROM emp_users
        WHERE email = :email
        AND id != :id
        LIMIT 1
    ";

    $emailStmt = $conn->prepare($emailCheckSql);

    $emailStmt->execute([
        ':email' => $email,
        ':id' => $userId
    ]);

    if ($emailStmt->fetch()) {
        http_response_code(409);

        echo json_encode([
            "success" => false,
            "message" => "Email address is already used by another user."
        ]);

        exit;
    }

    // ----------------------------------------
    // Update profile
    // ----------------------------------------
    $updateSql = "
        UPDATE emp_users
        SET
            phone = :phone,
            email = :email,
            location = :location,
            role = :role
        WHERE id = :id
    ";

    $updateStmt = $conn->prepare($updateSql);

    $updateStmt->execute([
        ':phone' => $phone,
        ':email' => $email,
        ':location' => $location,
        ':role' => $dbRole,
        ':id' => $userId
    ]);

    // ----------------------------------------
    // Get updated user
    // ----------------------------------------
    $selectSql = "
        SELECT
            id,
            full_name,
            employee_id,
            email,
            phone,
            country_code,
            department,
            designation,
            employee_type,
            date_of_birth,
            location,
            role,
            username
        FROM emp_users
        WHERE id = :id
        LIMIT 1
    ";

    $selectStmt = $conn->prepare($selectSql);

    $selectStmt->execute([
        ':id' => $userId
    ]);

    $user = $selectStmt->fetch(PDO::FETCH_ASSOC);

    // ----------------------------------------
    // Success
    // ----------------------------------------
    http_response_code(200);

    echo json_encode([
        "success" => true,
        "message" => "Profile updated successfully.",
        "user" => $user
    ]);

} catch (PDOException $e) {

    error_log($e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to update profile."
    ]);
}
