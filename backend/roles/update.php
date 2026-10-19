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
    "Access-Control-Allow-Methods: PUT, OPTIONS"
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
// ONLY PUT
// ============================================================

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Only PUT method is allowed."
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
        "Roles Update Authentication Error: "
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
// CHECK UPDATE PERMISSION
// ============================================================

requirePermission(
    $conn,
    $userId,
    'role_management',
    'update'
);


// ============================================================
// GET ROLE ID
// ============================================================

$id = isset($_GET['id'])
    ? (int)$_GET['id']
    : 0;


// ============================================================
// VALIDATE ROLE ID
// ============================================================

if ($id <= 0) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Invalid role ID."
    ]);

    exit;
}


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
        "message" => "Invalid role value."
    ]);

    exit;
}


// ============================================================
// DATABASE OPERATIONS
// ============================================================

try {

    // ========================================================
    // CHECK ROLE EXISTS
    // ========================================================

    $check = $conn->prepare("
        SELECT
            id,
            name,
            value,
            is_active
        FROM roles
        WHERE id = :id
        LIMIT 1
    ");

    $check->execute([
        ':id' => $id
    ]);

    $existingRole = $check->fetch(
        PDO::FETCH_ASSOC
    );


    // ========================================================
    // ROLE NOT FOUND
    // ========================================================

    if (!$existingRole) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Role not found."
        ]);

        exit;
    }


    // ========================================================
    // PREVENT ADMIN ROLE VALUE CHANGE
    // ========================================================
    //
    // Optional security rule:
    // The default admin role should not be renamed
    // to another role value.
    //
    // ========================================================

    if (
        strtolower($existingRole['value']) === 'admin' &&
        $value !== 'admin'
    ) {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" =>
            "The Administrator role value cannot be changed."
        ]);

        exit;
    }


    // ========================================================
    // CHECK DUPLICATE ROLE VALUE
    // ========================================================

    $duplicate = $conn->prepare("
        SELECT
            id
        FROM roles
        WHERE value = :value
          AND id != :id
        LIMIT 1
    ");

    $duplicate->execute([
        ':value' => $value,
        ':id' => $id
    ]);


    // ========================================================
    // DUPLICATE FOUND
    // ========================================================

    if ($duplicate->fetch(PDO::FETCH_ASSOC)) {

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
    // UPDATE ROLE
    // ========================================================

    $stmt = $conn->prepare("
        UPDATE roles
        SET
            name = :name,
            value = :value,
            is_active = :is_active
        WHERE id = :id
    ");


    // ========================================================
    // EXECUTE UPDATE
    // ========================================================

    $stmt->execute([
        ':name' => $name,
        ':value' => $value,
        ':is_active' => $isActive ? 1 : 0,
        ':id' => $id
    ]);


    // ========================================================
    // SUCCESS RESPONSE
    // ========================================================

    http_response_code(200);

    echo json_encode([

        "success" => true,

        "status" => "success",

        "message" =>
        "Role updated successfully.",

        "user_id" => $userId,

        "data" => [

            "id" => $id,

            "name" => $name,

            "value" => $value,

            "is_active" =>
            $isActive ? 1 : 0

        ]

    ]);
} catch (PDOException $e) {

    error_log(
        "Roles Update Database Error: "
            . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "status" => "error",

        "message" =>
        "Failed to update role."

    ]);

    exit;
}
