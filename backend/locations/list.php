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
        "Location List Authentication Error: " . $e->getMessage()
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

$userId = (int)$decoded->user_id;


// ============================================================
// FETCH LOCATIONS
// ============================================================

try {

    $query = "
        SELECT
            id,
            location_type,
            site_name,
            building_name,
            area_zone,
            floor,
            room_name,
            room_number,
            `condition`,
            code,
            created_at
        FROM locations
        WHERE created_by = :created_by
        ORDER BY created_at DESC
    ";

    $stmt = $conn->prepare($query);

    // IMPORTANT:
    // User ID comes only from JWT
    $stmt->bindValue(
        ":created_by",
        $userId,
        PDO::PARAM_INT
    );

    $stmt->execute();

    $locations = $stmt->fetchAll(PDO::FETCH_ASSOC);


    // ========================================================
    // SUCCESS RESPONSE
    // ========================================================

    http_response_code(200);

    echo json_encode([

        "success" => true,

        "status" => "success",

        "message" => "Locations retrieved successfully.",

        "user_id" => $userId,

        "count" => count($locations),

        "data" => $locations

    ]);
} catch (PDOException $e) {

    // ========================================================
    // DATABASE ERROR
    // ========================================================

    error_log(
        "Location List DB Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "status" => "error",

        "message" => "Unable to fetch locations. Please try again later."

    ]);
}
