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
header("Access-Control-Allow-Methods: POST, OPTIONS");
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
// ONLY POST
// ============================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Only POST method is allowed."
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
        "Location Create Authentication Error: " . $e->getMessage()
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
// READ JSON
// ============================================================

$input = file_get_contents("php://input");

$data = json_decode($input);

if ($data === null) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Invalid JSON data."
    ]);

    exit;
}


// ============================================================
// GET DATA
// ============================================================

$locationType  = trim($data->location_type ?? '');
$siteName      = trim($data->site_name ?? '');
$buildingName  = trim($data->building_name ?? '');
$areaZone      = trim($data->area_zone ?? '');
$floor         = trim($data->floor ?? '');
$roomName      = trim($data->room_name ?? '');
$roomNumber    = trim($data->room_number ?? '');
$condition     = trim($data->condition ?? '');
$code          = trim($data->code ?? '');
$criticality   = trim($data->criticality ?? '');


// ============================================================
// VALIDATION
// ============================================================

$requiredFields = [
    "location_type" => $locationType,
    "site_name"     => $siteName,
    "building_name" => $buildingName,
    "area_zone"     => $areaZone,
    "floor"         => $floor,
    "room_name"     => $roomName,
    "room_number"   => $roomNumber,
    "condition"     => $condition,
    "code"          => $code
];

foreach ($requiredFields as $field => $value) {

    if ($value === '') {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => ucfirst(str_replace('_', ' ', $field))
                . " is required."
        ]);

        exit;
    }
}


// ============================================================
// CREATE LOCATION
// ============================================================

try {

    // ========================================================
    // CHECK DUPLICATE LOCATION CODE
    // ========================================================

    $checkQuery = "
    SELECT id, code
    FROM locations
    WHERE TRIM(code) = TRIM(:code)
    LIMIT 1
";

    $checkStmt = $conn->prepare($checkQuery);

    $checkStmt->bindValue(
        ":code",
        $code,
        PDO::PARAM_STR
    );

    $checkStmt->execute();

    $existingLocation = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if ($existingLocation) {

        http_response_code(409);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Location code already exists.",
            "field" => "code",
            "existing_location_id" => (int)$existingLocation['id'],
            "existing_code" => $existingLocation['code']
        ]);

        exit;
    }

    // ========================================================
    // INSERT LOCATION
    // ========================================================

    $query = "
        INSERT INTO locations (
            location_type,
            site_name,
            building_name,
            area_zone,
            floor,
            room_name,
            room_number,
            `condition`,
            code,
            criticality,
            created_by,
            created_at
        )
        VALUES (
            :location_type,
            :site_name,
            :building_name,
            :area_zone,
            :floor,
            :room_name,
            :room_number,
            :condition,
            :code,
            :criticality,
            :created_by,
            NOW()
        )
    ";

    $stmt = $conn->prepare($query);


    // ========================================================
    // BIND VALUES
    // ========================================================

    $stmt->bindValue(
        ":location_type",
        $locationType,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":site_name",
        $siteName,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":building_name",
        $buildingName,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":area_zone",
        $areaZone,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":floor",
        $floor,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":room_name",
        $roomName,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":room_number",
        $roomNumber,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":condition",
        $condition,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":code",
        $code,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ":criticality",
        $criticality,
        PDO::PARAM_STR
    );

    // IMPORTANT:
    // created_by comes ONLY from JWT
    $stmt->bindValue(
        ":created_by",
        $userId,
        PDO::PARAM_INT
    );


    // ========================================================
    // EXECUTE
    // ========================================================

    if ($stmt->execute()) {

        $locationId = (int)$conn->lastInsertId();

        http_response_code(201);

        echo json_encode([

            "success" => true,

            "status" => "success",

            "message" => "Location was created successfully.",

            "location_id" => $locationId,

            "created_by" => $userId

        ]);

        exit;
    }


    // ========================================================
    // INSERT FAILED
    // ========================================================

    http_response_code(503);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unable to create location."
    ]);


    // ============================================================
    // DATABASE ERROR
    // ============================================================

} catch (PDOException $e) {

    error_log(
        "Location Create DB Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unable to create location. Please try again later."
    ]);
}
