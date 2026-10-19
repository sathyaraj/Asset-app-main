<?php

// ============================================================
// REQUIRED FILES
// ============================================================

require_once '../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';


// ============================================================
// HEADERS
// ============================================================

header("Access-Control-Allow-Origin: *");
header(
    "Access-Control-Allow-Methods: POST, OPTIONS"
);
header(
    "Access-Control-Allow-Headers: Content-Type, Authorization"
);
header(
    "Content-Type: application/json; charset=UTF-8"
);


// ============================================================
// OPTIONS
// ============================================================

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {

    http_response_code(200);
    exit;
}


// ============================================================
// ONLY POST
// ============================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Only POST method is allowed."
    ]);

    exit;
}


// ============================================================
// JWT AUTHENTICATION
// ============================================================

try {

    $decoded = authenticate();
} catch (Exception $e) {

    error_log(
        "Roles Create Authentication Error: "
            . $e->getMessage()
    );

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" =>
        "Unauthorized. Invalid or expired token."
    ]);

    exit;
}


// ============================================================
// GET USER ID FROM JWT
// ============================================================

if (
    !isset($decoded->user_id) ||
    empty($decoded->user_id)
) {

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" =>
        "User information not found in token."
    ]);

    exit;
}

$userId = (int)$decoded->user_id;


// ============================================================
// CHECK CREATE PERMISSION
// ============================================================

requirePermission(
    $conn,
    $userId,
    'role_management',
    'create'
);


// ============================================================
// READ JSON INPUT
// ============================================================

$input = json_decode(
    file_get_contents('php://input'),
    true
);


// ============================================================
// VALIDATE JSON
// ============================================================

if (!is_array($input)) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Invalid JSON data."
    ]);

    exit;
}


// ============================================================
// GET INPUT VALUES
// ============================================================

$name = trim(
    $input['name'] ?? ''
);

$value = trim(
    $input['value'] ?? ''
);

$isActive = isset($input['is_active'])
    ? (int)$input['is_active']
    : 1;


// ============================================================
// VALIDATE ROLE NAME
// ============================================================

if ($name === '') {

    http_response_code(422);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Role name is required."
    ]);

    exit;
}


// ============================================================
// VALIDATE ROLE VALUE
// ============================================================

if ($value === '') {

    http_response_code(422);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Role value is required."
    ]);

    exit;
}


// ============================================================
// NORMALIZE ROLE VALUE
// ============================================================
//
// Example:
//
// CAFM Manager
//      ↓
// cafm_manager
//
// Facilities Executive
//      ↓
// facilities_executive
//
// ============================================================

$value = strtolower(
    preg_replace(
        '/\s+/',
        '_',
        $value
    )
);


// ============================================================
// REMOVE UNWANTED CHARACTERS
// ============================================================

$value = preg_replace(
    '/[^a-z0-9_]/',
    '',
    $value
);


// ============================================================
// VALIDATE NORMALIZED VALUE
// ============================================================

if ($value === '') {

    http_response_code(422);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" =>
        "Invalid role value."
    ]);

    exit;
}


// ============================================================
// DATABASE
// ============================================================

try {

    // ========================================================
    // CHECK DUPLICATE ROLE VALUE
    // ========================================================

    $check = $conn->prepare("
        SELECT id
        FROM roles
        WHERE value = :value
        LIMIT 1
    ");

    $check->execute([
        ':value' => $value
    ]);


    // ========================================================
    // DUPLICATE
    // ========================================================

    if ($check->fetch(PDO::FETCH_ASSOC)) {

        http_response_code(409);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" =>
            "Role value already exists."
        ]);

        exit;
    }


    // ========================================================
    // INSERT ROLE
    // ========================================================

    $stmt = $conn->prepare("
        INSERT INTO roles
        (
            name,
            value,
            is_active
        )
        VALUES
        (
            :name,
            :value,
            :is_active
        )
    ");


    // ========================================================
    // EXECUTE
    // ========================================================

    $stmt->execute([
        ':name' => $name,
        ':value' => $value,
        ':is_active' => $isActive ? 1 : 0
    ]);


    // ========================================================
    // GET INSERT ID
    // ========================================================

    $roleId = (int)$conn->lastInsertId();


    // ========================================================
    // SUCCESS RESPONSE
    // ========================================================

    http_response_code(201);

    echo json_encode([

        "success" => true,

        "status" => "success",

        "message" =>
        "Role created successfully.",

        "user_id" => $userId,

        "data" => [

            "id" => $roleId,

            "name" => $name,

            "value" => $value,

            "is_active" =>
            $isActive ? 1 : 0

        ]

    ]);
} catch (PDOException $e) {

    error_log(
        "Roles Create Database Error: "
            . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "status" => "error",

        "message" =>
        "Failed to create role."

    ]);

    exit;
}
