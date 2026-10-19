<?php
require_once __DIR__ . '/../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Only GET method is allowed."
    ]);

    exit;
}

try {

    // ============================================================
    // 1. Authenticate JWT
    // ============================================================

    $decoded = authenticate();

    if (
        !$decoded ||
        !isset($decoded->user_id) ||
        empty($decoded->user_id)
    ) {
        http_response_code(401);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Unauthorized."
        ]);

        exit;
    }

    $userId = (int)$decoded->user_id;


    // ============================================================
    // 2. Check Role Management View Permission
    // ============================================================

    requirePermission(
        $conn,
        $userId,
        'role_management',
        'view'
    );


    // ============================================================
    // 3. Get role_id
    // ============================================================

    $roleId = isset($_GET['role_id'])
        ? (int)$_GET['role_id']
        : 0;

    if ($roleId <= 0) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "role_id is required."
        ]);

        exit;
    }


    // ============================================================
    // 4. Get role from roles table
    //
    // Example:
    //
    // role_id = 1
    //       ↓
    // roles.id = 1
    //       ↓
    // roles.value = admin
    // ============================================================

    $roleStmt = $conn->prepare("
        SELECT
            id,
            name,
            value,
            is_active
        FROM roles
        WHERE id = :role_id
        LIMIT 1
    ");

    $roleStmt->execute([
        ':role_id' => $roleId
    ]);

    $role = $roleStmt->fetch(PDO::FETCH_ASSOC);


    // ============================================================
    // 5. Validate role
    // ============================================================

    if (!$role) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Role not found."
        ]);

        exit;
    }


    if ((int)$role['is_active'] !== 1) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Selected role is inactive."
        ]);

        exit;
    }


    $roleValue = trim((string)$role['value']);

    if ($roleValue === '') {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Role value is not configured."
        ]);

        exit;
    }


    // ============================================================
    // 6. Get all active pages and selected role permissions
    //
    // role_page_permissions.role stores role VALUE:
    //
    // admin
    // cafm_manager
    // supervisor
    // facilities_executive
    // technician
    //
    // NOT role_id.
    // ============================================================

    $stmt = $conn->prepare("
        SELECT
            p.id AS page_id,
            p.page_name,
            p.page_key,
            p.icon,
            p.is_active,

            COALESCE(
                rpp.can_view,
                0
            ) AS can_view,

            COALESCE(
                rpp.can_create,
                0
            ) AS can_create,

            COALESCE(
                rpp.can_update,
                0
            ) AS can_update,

            COALESCE(
                rpp.can_delete,
                0
            ) AS can_delete

        FROM pages p

        LEFT JOIN role_page_permissions rpp
            ON rpp.page_id = p.id
            AND rpp.role = :role_value

        WHERE p.is_active = 1

        ORDER BY p.id ASC
    ");

    $stmt->execute([
        ':role_value' => $roleValue
    ]);

    $permissions = $stmt->fetchAll(PDO::FETCH_ASSOC);


    // ============================================================
    // 7. Success response
    // ============================================================

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Permissions retrieved successfully.",

        "role_id" => (int)$role['id'],

        "role" => [
            "id" => (int)$role['id'],
            "name" => $role['name'],
            "value" => $roleValue,
            "is_active" => (int)$role['is_active']
        ],

        "data" => $permissions
    ]);

    exit;


} catch (PDOException $e) {

    error_log(
        "Permissions List Database Error: " .
        $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Failed to retrieve permissions."
    ]);

    exit;


} catch (Exception $e) {

    error_log(
        "Permissions List Error: " .
        $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "An unexpected error occurred."
    ]);

    exit;
}