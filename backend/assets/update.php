<?php

require_once '../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, PATCH, OPTIONS");
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
// ONLY PUT / PATCH
// ============================================================

if (
    $_SERVER['REQUEST_METHOD'] !== 'PUT' &&
    $_SERVER['REQUEST_METHOD'] !== 'PATCH'
) {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Method not allowed. Only PUT or PATCH is allowed."
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
// READ JSON BODY
// ============================================================

$rawData = file_get_contents("php://input");

if (empty($rawData)) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Request body is empty."
    ]);

    exit;
}

$data = json_decode($rawData);

if (
    json_last_error() !== JSON_ERROR_NONE ||
    !$data
) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Invalid JSON data."
    ]);

    exit;
}

// ============================================================
// ASSET ID VALIDATION
// ============================================================

if (
    !isset($data->id) ||
    !is_numeric($data->id)
) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Valid asset ID is required."
    ]);

    exit;
}

$assetId = (int) $data->id;

if ($assetId <= 0) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Invalid asset ID."
    ]);

    exit;
}

// ============================================================
// CHECK ASSET OWNERSHIP
// ============================================================

try {

    $checkSql = "
        SELECT
            id,
            asset_name,
            asset_code,
            created_by,
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

    // Asset not found
    if (!$asset) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Asset not found."
        ]);

        exit;
    }

    // Deleted asset cannot be edited
    if ($asset['status'] === 'DELETED') {

        http_response_code(409);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Deleted asset cannot be updated."
        ]);

        exit;
    }

    // ========================================================
    // USER OWNERSHIP CHECK
    // ========================================================

    if ((int) $asset['created_by'] !== $userId) {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "You are not authorized to update this asset."
        ]);

        exit;
    }

    // ========================================================
    // ALLOWED FIELDS
    // ========================================================

    $allowed = [

        'location_id',
        'description',
        'quantity',
        'system',
        'tag',
        'type',

        'asset_name',
        'group_name',
        'classification',
        'asset_condition',
        'product_code',

        'model_type',
        'manufacturer',

        'purchase_date',
        'warranty_expiry_date',
        'purchase_cost',
        'supplier',

        'cost_center',
        'comments',
        'status',

        'installed_time',

        'visual_inspection',

        'image_base64',
        'image_name',
        'image_taken_at'
    ];

    // ========================================================
    // LEGACY LOCATION ALIAS
    // ========================================================

    if (
        property_exists($data, 'location') &&
        !property_exists($data, 'location_id')
    ) {

        $data->location_id = $data->location;
    }

    // ========================================================
    // NORMALIZE LOCATION
    // ========================================================

    if (
        property_exists($data, 'location_id') &&
        $data->location_id !== null &&
        $data->location_id !== '' &&
        !is_numeric($data->location_id)
    ) {

        $data->location_id = null;
    }

    // ========================================================
    // NORMALIZE WARRANTY DATE
    // ========================================================

    if (
        property_exists($data, 'warranty_expiry_date') &&
        !empty($data->warranty_expiry_date)
    ) {

        $timestamp = strtotime(
            $data->warranty_expiry_date
        );

        $data->warranty_expiry_date =
            $timestamp !== false
                ? date('Y-m-d', $timestamp)
                : null;
    }

    // ========================================================
    // LEGACY WARRANTY DATE
    // ========================================================

    elseif (
        property_exists($data, 'warrantyExpiryDate') &&
        !empty($data->warrantyExpiryDate)
    ) {

        $timestamp = strtotime(
            $data->warrantyExpiryDate
        );

        $data->warranty_expiry_date =
            $timestamp !== false
                ? date('Y-m-d', $timestamp)
                : null;
    }

    // ========================================================
    // NORMALIZE IMAGE TAKEN DATE
    // ========================================================

    if (
        property_exists($data, 'image_taken_at') &&
        !empty($data->image_taken_at)
    ) {

        $timestamp = strtotime(
            $data->image_taken_at
        );

        $data->image_taken_at =
            $timestamp !== false
                ? date('Y-m-d H:i:s', $timestamp)
                : null;
    }

    // ========================================================
    // BUILD UPDATE QUERY
    // ========================================================

    $setParts = [];
    $params = [];

    foreach ($allowed as $column) {

        if (property_exists($data, $column)) {

            $setParts[] = "$column = :$column";

            $params[$column] = $data->$column;
        }
    }

    // ========================================================
    // NO FIELDS
    // ========================================================

    if (empty($setParts)) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "No fields to update."
        ]);

        exit;
    }

    // ========================================================
    // UPDATE SQL
    // ========================================================

    $sql = "
        UPDATE assets
        SET " . implode(", ", $setParts) . "
        WHERE id = :id
        AND created_by = :created_by
        AND status != 'DELETED'
    ";

    $stmt = $conn->prepare($sql);

    // ========================================================
    // BIND UPDATE VALUES
    // ========================================================

    foreach ($params as $key => $value) {

        // Integer fields
        if (
            in_array($key, [
                'location_id',
                'quantity'
            ])
        ) {

            if ($value === null || $value === '') {

                $stmt->bindValue(
                    ":$key",
                    null,
                    PDO::PARAM_NULL
                );

            } else {

                $stmt->bindValue(
                    ":$key",
                    (int) $value,
                    PDO::PARAM_INT
                );
            }

        } else {

            if ($value === null) {

                $stmt->bindValue(
                    ":$key",
                    null,
                    PDO::PARAM_NULL
                );

            } else {

                $stmt->bindValue(
                    ":$key",
                    $value
                );
            }
        }
    }

    // ========================================================
    // ID
    // ========================================================

    $stmt->bindValue(
        ':id',
        $assetId,
        PDO::PARAM_INT
    );

    // ========================================================
    // CREATED BY
    // FROM JWT ONLY
    // ========================================================

    $stmt->bindValue(
        ':created_by',
        $userId,
        PDO::PARAM_INT
    );

    // ========================================================
    // EXECUTE
    // ========================================================

    $stmt->execute();

    // ========================================================
    // SUCCESS
    // ========================================================

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Asset updated successfully.",
        "data" => [
            "asset_id" => $assetId,
            "updated_by" => $userId
        ]
    ]);

} catch (PDOException $e) {

    // Log actual database error
    error_log($e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unable to update asset."
    ]);
}
?>