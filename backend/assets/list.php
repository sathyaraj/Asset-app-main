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
        "message" => "Method not allowed. Only GET is allowed."
    ]);

    exit;
}

// ============================================================
// JWT AUTHENTICATION
// ============================================================

try {

    $decoded = authenticate();
} catch (Exception $e) {

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Authentication required."
    ]);

    exit;
}

// ============================================================
// GET USER ID FROM JWT
// ============================================================

$userId = isset($decoded->user_id)
    ? (int) $decoded->user_id
    : 0;

if ($userId <= 0) {

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Invalid user information in token."
    ]);

    exit;
}

// ============================================================
// GET USER ASSETS
// ============================================================

try {

    // ========================================================
    // TOTAL ASSETS FOR LOGGED-IN USER
    // ========================================================

    $totalSql = "
        SELECT COUNT(*) AS total
        FROM assets
        WHERE created_by = :created_by
        AND deleted_at IS NULL
    ";

    $totalStmt = $conn->prepare($totalSql);

    $totalStmt->execute([
        ':created_by' => $userId
    ]);

    $totalAssets = (int) $totalStmt
        ->fetch(PDO::FETCH_ASSOC)['total'];


    // ========================================================
    // MAINTENANCE ASSETS FOR LOGGED-IN USER
    // ========================================================

    $maintenanceSql = "
        SELECT COUNT(*) AS total
        FROM assets
        WHERE created_by = :created_by
        AND status = 'MAINTENANCE'
    ";

    $maintenanceStmt = $conn->prepare($maintenanceSql);

    $maintenanceStmt->execute([
        ':created_by' => $userId
    ]);

    $maintenanceAssets = (int) $maintenanceStmt
        ->fetch(PDO::FETCH_ASSOC)['total'];


    // ========================================================
    // GET ASSETS FOR LOGGED-IN USER
    // ========================================================

    $sql = "
        SELECT
            a.*,

            CONCAT(
                COALESCE(l.site_name, ''),
                CASE
                    WHEN l.room_name IS NOT NULL
                         AND l.room_name != ''
                    THEN CONCAT(' (', l.room_name, ')')
                    ELSE ''
                END
            ) AS location_display

        FROM assets a

        LEFT JOIN locations l
            ON a.location_id = l.id

        WHERE a.created_by = :created_by

       AND deleted_at IS NULL

        ORDER BY a.created_at DESC
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ':created_by' => $userId
    ]);

    $assets = $stmt->fetchAll(PDO::FETCH_ASSOC);


    // ========================================================
    // SUCCESS RESPONSE
    // ========================================================

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Assets retrieved successfully.",

        "user_id" => $userId,

        "stats" => [
            "total_assets" => $totalAssets,
            "in_maintenance" => $maintenanceAssets
        ],

        "data" => $assets
    ]);
} catch (PDOException $e) {

    // Log actual database error
    error_log($e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unable to fetch assets."
    ]);
}
