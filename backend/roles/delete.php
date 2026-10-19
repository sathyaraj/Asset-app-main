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
    "Access-Control-Allow-Methods: DELETE, OPTIONS"
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
// ONLY DELETE
// ============================================================

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Only DELETE method is allowed."
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
        "Roles Delete Authentication Error: "
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
// CHECK DELETE PERMISSION
// ============================================================

requirePermission(
    $conn,
    $userId,
    'role_management',
    'delete'
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

    $role = $check->fetch(
        PDO::FETCH_ASSOC
    );


    // ========================================================
    // ROLE NOT FOUND
    // ========================================================

    if (!$role) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Role not found."
        ]);

        exit;
    }


    // ========================================================
    // PREVENT ADMINISTRATOR DELETE
    // ========================================================

    if (
        strtolower(
            trim($role['value'])
        ) === 'admin'
    ) {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" =>
            "Administrator role cannot be deleted."
        ]);

        exit;
    }


    // ========================================================
    // DELETE ROLE
    // ========================================================

    $stmt = $conn->prepare("
        DELETE FROM roles
        WHERE id = :id
    ");

    $stmt->execute([
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
        "Role deleted successfully.",

        "user_id" => $userId,

        "data" => [

            "id" => $id,

            "name" => $role['name'],

            "value" => $role['value']

        ]

    ]);
} catch (PDOException $e) {

    error_log(
        "Roles Delete Database Error: "
            . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "status" => "error",

        "message" =>
        "Failed to delete role."

    ]);

    exit;
}
