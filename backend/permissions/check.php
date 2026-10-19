<?php

require_once __DIR__ . '/../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';

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
    // 2. Get page and action
    // ============================================================

    $pageKey = trim($_GET['page'] ?? '');
    $action  = trim($_GET['action'] ?? 'view');

    $allowedActions = [
        'view',
        'create',
        'update',
        'delete'
    ];


    // ============================================================
    // 3. Validate page
    // ============================================================

    if ($pageKey === '') {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Page is required."
        ]);

        exit;
    }


    // ============================================================
    // 4. Validate action
    // ============================================================

    if (!in_array($action, $allowedActions, true)) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Invalid action."
        ]);

        exit;
    }


    // ============================================================
    // 5. Get logged-in user's role
    //
    // Current database:
    // emp_users.role = admin / technician / supervisor / etc.
    // ============================================================

    $userStmt = $conn->prepare("
        SELECT
            id,
            full_name,
            employee_id,
            username,
            role
        FROM emp_users
        WHERE id = :user_id
        LIMIT 1
    ");

    $userStmt->execute([
        ':user_id' => $userId
    ]);

    $user = $userStmt->fetch(PDO::FETCH_ASSOC);


    // ============================================================
    // 6. User not found
    // ============================================================

    if (!$user) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "User not found."
        ]);

        exit;
    }


    // ============================================================
    // 7. Get role value
    // ============================================================

    $roleValue = trim((string)($user['role'] ?? ''));

    if ($roleValue === '') {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "User role is not configured."
        ]);

        exit;
    }


    // ============================================================
    // 8. Map action to permission column
    // ============================================================

    $columnMap = [
        'view'   => 'can_view',
        'create' => 'can_create',
        'update' => 'can_update',
        'delete' => 'can_delete'
    ];

    $column = $columnMap[$action];


    // ============================================================
    // 9. Check permission
    //
    // Current database:
    //
    // role_page_permissions.role = role VALUE
    //
    // Example:
    // admin
    // technician
    // supervisor
    //
    // NOT role_id
    // ============================================================

    $sql = "
        SELECT
            rpp.$column AS allowed
        FROM role_page_permissions rpp

        INNER JOIN roles r
            ON r.value = rpp.role

        INNER JOIN pages p
            ON p.id = rpp.page_id

        WHERE r.value = :role
          AND p.page_key = :page_key
          AND r.is_active = 1
          AND p.is_active = 1

        LIMIT 1
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ':role'     => $roleValue,
        ':page_key' => $pageKey
    ]);

    $result = $stmt->fetch(PDO::FETCH_ASSOC);


    // ============================================================
    // 10. Convert permission to boolean
    // ============================================================

    $allowed = (
        $result &&
        isset($result['allowed']) &&
        (int)$result['allowed'] === 1
    );


    // ============================================================
    // 11. Success response
    // ============================================================

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "allowed" => $allowed,
        "page" => $pageKey,
        "action" => $action,
        "user_id" => $userId,
        "role" => $roleValue
    ]);

    exit;
} catch (PDOException $e) {

    error_log(
        "Permission Check Database Error: " .
            $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Failed to check permission."
    ]);

    exit;
} catch (Exception $e) {

    error_log(
        "Permission Check Error: " .
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
