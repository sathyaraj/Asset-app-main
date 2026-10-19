<?php

// ============================================================
// REQUIRED FILES
// ============================================================

require_once __DIR__ . '/../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';


// ============================================================
// HEADERS
// ============================================================

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");


// ============================================================
// OPTIONS
// ============================================================

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}


// ============================================================
// ONLY GET
// ============================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Only GET method is allowed."
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
        "Roles List Authentication Error: " . $e->getMessage()
    );

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unauthorized. Invalid or expired token."
    ]);

    exit;
}


// ============================================================
// GET USER ID FROM JWT
// ============================================================

if (
    !$decoded ||
    !isset($decoded->user_id) ||
    empty($decoded->user_id)
) {

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "User information not found in token."
    ]);

    exit;
}

$userId = (int) $decoded->user_id;


// ============================================================
// CHECK ROLE MANAGEMENT PERMISSION
// ============================================================

// requirePermission(
//     $conn,
//     $userId,
//     'role_management',
//     'view'
// );


// ============================================================
// GET ROLES
// ============================================================

try {

    // $stmt = $conn->prepare("
    //     SELECT
    //         id,
    //         name,
    //         value,
    //         is_active,
    //         created_at
    //     FROM roles
    //     ORDER BY id ASC
    // ");
    $stmt = $conn->prepare("
    SELECT DISTINCT
        r.id,
        r.name,
        r.value,
        r.is_active,
        r.created_at
    FROM roles r
    INNER JOIN role_page_permissions rpp
        ON rpp.role = r.value
    WHERE r.is_active = 1
    ORDER BY r.id ASC
");

    $stmt->execute();

    $roles = $stmt->fetchAll(PDO::FETCH_ASSOC);


    // ========================================================
    // CONVERT VALUES
    // ========================================================

    foreach ($roles as &$role) {

        $role['id'] = (int) $role['id'];

        $role['is_active'] = (int) $role['is_active'];
    }

    unset($role);


    // ========================================================
    // RESPONSE
    // ========================================================

    http_response_code(200);

    echo json_encode([

        "success" => true,

        "status" => "success",

        "message" => "Roles retrieved successfully.",

        "user_id" => $userId,

        "roles" => $roles

    ]);
} catch (PDOException $e) {

    error_log(
        "Roles List Database Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "status" => "error",

        "message" => "Failed to retrieve roles."

    ]);

    exit;
}
