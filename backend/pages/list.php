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

    // Authenticate JWT
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

    // Check Role Management -> View permission
    requirePermission(
        $conn,
        $userId,
        'role_management',
        'view'
    );

    // Get active pages
    $stmt = $conn->prepare("
        SELECT
            id,
            page_name,
            page_key,
            icon,
            is_active
        FROM pages
        WHERE is_active = 1
        ORDER BY id ASC
    ");

    $stmt->execute();

    $pages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Pages retrieved successfully.",
        "data" => $pages
    ]);
} catch (PDOException $e) {

    error_log(
        "Pages List Database Error: "
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
        "Pages List Error: "
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
