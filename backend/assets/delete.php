<?php

require_once '../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// --------------------------------------------------
// Handle OPTIONS
// --------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// --------------------------------------------------
// Only POST allowed
// --------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {

    http_response_code(405);

    echo json_encode([
        "status" => "error",
        "message" => "Method not allowed."
    ]);

    exit;
}

// --------------------------------------------------
// Authenticate JWT
// --------------------------------------------------
$decoded = authenticate();

// --------------------------------------------------
// Get user ID from JWT
// --------------------------------------------------
$userId = isset($decoded->user_id)
    ? (int) $decoded->user_id
    : 0;

if ($userId <= 0) {

    http_response_code(401);

    echo json_encode([
        "status" => "error",
        "message" => "Invalid user information in token."
    ]);

    exit;
}

// --------------------------------------------------
// Read JSON body
// --------------------------------------------------
$data = json_decode(
    file_get_contents("php://input")
);

if (
    !$data ||
    empty($data->id)
) {

    http_response_code(400);

    echo json_encode([
        "status" => "error",
        "message" => "Asset ID is required."
    ]);

    exit;
}

$assetId = (int) $data->id;

if ($assetId <= 0) {

    http_response_code(400);

    echo json_encode([
        "status" => "error",
        "message" => "Invalid asset ID."
    ]);

    exit;
}

try {

    // --------------------------------------------------
    // Check asset exists
    // --------------------------------------------------
    $checkSql = "
        SELECT
            id,
            asset_name,
            asset_code,
            status
        FROM assets
        WHERE id = :id
        LIMIT 1
    ";

    $checkStmt = $conn->prepare($checkSql);

    $checkStmt->execute([
        ':id' => $assetId
    ]);

    $asset = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$asset) {

        http_response_code(404);

        echo json_encode([
            "status" => "error",
            "message" => "Asset not found."
        ]);

        exit;
    }

    // --------------------------------------------------
    // Already deleted
    // --------------------------------------------------
    if ($asset['status'] === 'DELETED') {

        http_response_code(409);

        echo json_encode([
            "status" => "error",
            "message" => "Asset has already been deleted."
        ]);

        exit;
    }

    // --------------------------------------------------
    // Soft Delete
    // --------------------------------------------------
    $sql = "
        UPDATE assets
        SET
            status = 'DELETED',
            deleted_by = :deleted_by,
            deleted_at = NOW()
        WHERE id = :id
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ':deleted_by' => $userId,
        ':id' => $assetId
    ]);

    if ($stmt->rowCount() > 0) {

        http_response_code(200);

        echo json_encode([
            "status" => "success",
            "message" => "Asset deleted successfully.",
            "data" => [
                "asset_id" => $assetId,
                "asset_name" => $asset['asset_name'],
                "asset_code" => $asset['asset_code'],
                "deleted_by" => $userId,
                "deleted_at" => date('Y-m-d H:i:s')
            ]
        ]);
    } else {

        http_response_code(500);

        echo json_encode([
            "status" => "error",
            "message" => "Unable to delete asset."
        ]);
    }
} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([
        "status" => "error",
        "message" => "Database error occurred."
    ]);

    // Development only:
    // error_log($e->getMessage());
}
