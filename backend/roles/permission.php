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

    $decoded = authenticate();

    if (!$decoded || !isset($decoded->user_id)) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Unauthorized."
        ]);

        exit;
    }

    $roleId = isset($_GET['role_id'])
        ? (int)$_GET['role_id']
        : 0;

    if ($roleId <= 0) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Invalid role ID."
        ]);

        exit;
    }

    $roleStmt = $conn->prepare("
        SELECT id, name, value, is_active
        FROM roles
        WHERE id = ?
        LIMIT 1
    ");

    $roleStmt->execute([$roleId]);

    $role = $roleStmt->fetch(PDO::FETCH_ASSOC);

    if (!$role) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Role not found."
        ]);

        exit;
    }

    $stmt = $conn->prepare("
        SELECT
            p.id AS page_id,
            p.page_name,
            p.page_key,
            p.icon,
            p.is_active,

            COALESCE(r.can_view, 0) AS can_view,
            COALESCE(r.can_create, 0) AS can_create,
            COALESCE(r.can_update, 0) AS can_update,
            COALESCE(r.can_delete, 0) AS can_delete

        FROM pages p

        LEFT JOIN role_page_permissions r
            ON r.page_id = p.id
            AND r.role = ?

        WHERE p.is_active = 1

        ORDER BY p.id ASC
    ");

    $stmt->execute([$role['value']]);

    $pages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($pages as &$page) {

        $page['page_id'] = (int)$page['page_id'];
        $page['is_active'] = (int)$page['is_active'];
        $page['can_view'] = (int)$page['can_view'];
        $page['can_create'] = (int)$page['can_create'];
        $page['can_update'] = (int)$page['can_update'];
        $page['can_delete'] = (int)$page['can_delete'];
    }

    unset($page);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Permissions retrieved successfully.",
        "role" => [
            "id" => (int)$role['id'],
            "name" => $role['name'],
            "value" => $role['value'],
            "is_active" => (int)$role['is_active']
        ],
        "pages" => $pages
    ]);
} catch (PDOException $e) {

    error_log("Permissions Database Error: " . $e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Failed to retrieve permissions."
    ]);
} catch (Exception $e) {

    error_log("Permissions Error: " . $e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "An unexpected error occurred."
    ]);
}
