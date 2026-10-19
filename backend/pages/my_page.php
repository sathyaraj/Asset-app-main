<?php

require_once '../db_connection.php';
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

    // =========================================================
    // AUTHENTICATE JWT
    // =========================================================

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

    // =========================================================
    // GET LOGGED-IN USER
    // =========================================================

    $userStmt = $conn->prepare("
        SELECT
            id,
            full_name,
            employee_id,
            username,
            role,
            status,
            login_access
        FROM emp_users
        WHERE id = ?
        LIMIT 1
    ");

    $userStmt->execute([$userId]);

    $user = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(401);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "User not found."
        ]);

        exit;
    }

    // =========================================================
    // CHECK USER STATUS
    // =========================================================

    if (
        $user['status'] !== 'active' ||
        (int)$user['login_access'] !== 1
    ) {
        http_response_code(403);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Your account does not have login access."
        ]);

        exit;
    }

    // =========================================================
    // USER ROLE
    // =========================================================

    $role = $user['role'];

    if (empty($role)) {
        http_response_code(403);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "No role assigned to this user."
        ]);

        exit;
    }

    // =========================================================
    // GET PAGES + ROLE PERMISSIONS
    // =========================================================

    $stmt = $conn->prepare("
        SELECT
            p.id,
            p.page_name,
            p.page_key,
            p.icon,
            p.is_active,

            r.can_view,
            r.can_create,
            r.can_update,
            r.can_delete

        FROM pages p

        INNER JOIN role_page_permissions r
            ON r.page_id = p.id

        WHERE
            p.is_active = 1
            AND r.role = ?
            AND r.can_view = 1

        ORDER BY p.id ASC
    ");

    $stmt->execute([$role]);

    $pages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // =========================================================
    // FORMAT BOOLEAN VALUES
    // =========================================================

    foreach ($pages as &$page) {

        $page['id'] = (int)$page['id'];

        $page['is_active'] = (int)$page['is_active'];

        $page['can_view'] = (int)$page['can_view'];

        $page['can_create'] = (int)$page['can_create'];

        $page['can_update'] = (int)$page['can_update'];

        $page['can_delete'] = (int)$page['can_delete'];
    }

    unset($page);

    // =========================================================
    // RESPONSE
    // =========================================================

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Pages retrieved successfully.",

        "user" => [
            "id" => (int)$user['id'],
            "full_name" => $user['full_name'],
            "employee_id" => $user['employee_id'],
            "username" => $user['username'],
            "role" => $role
        ],

        "pages" => $pages
    ]);
} catch (PDOException $e) {

    error_log(
        "My Pages Database Error: "
            . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Failed to retrieve pages."
    ]);

    exit;
} catch (Exception $e) {

    error_log(
        "My Pages Error: "
            . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "An unexpected error occurred."
    ]);

    exit;
}
