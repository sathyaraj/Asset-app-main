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
        "message" => "Method not allowed. Only POST is allowed."
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

$userId = 0;

if (isset($decoded->user_id)) {
    $userId = (int) $decoded->user_id;
}

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
// READ JSON
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

if (json_last_error() !== JSON_ERROR_NONE || !$data) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Invalid JSON data."
    ]);

    exit;
}

// ============================================================
// REQUIRED FIELDS
// ============================================================

if (
    empty($data->asset_name) ||
    empty($data->asset_code)
) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Asset name and asset code are required."
    ]);

    exit;
}

// ============================================================
// CREATE ASSET
// ============================================================

try {

    // ========================================================
    // LOCATION
    // ========================================================

    $locationId = $data->location_id
        ?? $data->location
        ?? null;

    if (
        $locationId !== null &&
        $locationId !== '' &&
        !is_numeric($locationId)
    ) {
        $locationId = null;
    }

    // ========================================================
    // WARRANTY EXPIRY DATE
    // ========================================================

    $warrantyExpiry = null;

    if (!empty($data->warranty_expiry_date)) {

        $timestamp = strtotime(
            $data->warranty_expiry_date
        );

        if ($timestamp !== false) {

            $warrantyExpiry = date(
                'Y-m-d',
                $timestamp
            );
        }
    } elseif (!empty($data->warrantyExpiryDate)) {

        $timestamp = strtotime(
            $data->warrantyExpiryDate
        );

        if ($timestamp !== false) {

            $warrantyExpiry = date(
                'Y-m-d',
                $timestamp
            );
        }
    }

    // ========================================================
    // IMAGE TAKEN AT
    // ========================================================

    $imageTakenAt = null;

    if (!empty($data->image_taken_at)) {

        $timestamp = strtotime(
            $data->image_taken_at
        );

        if ($timestamp !== false) {

            $imageTakenAt = date(
                'Y-m-d H:i:s',
                $timestamp
            );
        }
    }

    // ========================================================
    // SQL
    // ========================================================

    $sql = "
        INSERT INTO assets (

            location_id,
            asset_code,
            description,
            quantity,
            system,
            tag,
            type,

            asset_name,
            group_name,
            classification,
            asset_condition,
            product_code,

            model_type,
            manufacturer,

            purchase_date,
            warranty_expiry_date,
            purchase_cost,
            supplier,

            cost_center,
            comments,
            status,

            visual_inspection,

            image_base64,
            image_name,
            image_taken_at,

            installed_time,

            created_by

        ) VALUES (

            :location_id,
            :asset_code,
            :description,
            :quantity,
            :system,
            :tag,
            :type,

            :asset_name,
            :group_name,
            :classification,
            :asset_condition,
            :product_code,

            :model_type,
            :manufacturer,

            :purchase_date,
            :warranty_expiry_date,
            :purchase_cost,
            :supplier,

            :cost_center,
            :comments,
            :status,

            :visual_inspection,

            :image_base64,
            :image_name,
            :image_taken_at,

            :installed_time,

            :created_by

        )
    ";

    $stmt = $conn->prepare($sql);

    // ========================================================
    // LOCATION
    // ========================================================

    if ($locationId !== null && $locationId !== '') {

        $stmt->bindValue(
            ':location_id',
            (int) $locationId,
            PDO::PARAM_INT
        );
    } else {

        $stmt->bindValue(
            ':location_id',
            null,
            PDO::PARAM_NULL
        );
    }

    // ========================================================
    // ASSET DATA
    // ========================================================

    $stmt->bindValue(
        ':asset_code',
        trim($data->asset_code)
    );

    $stmt->bindValue(
        ':description',
        $data->description ?? ''
    );

    $stmt->bindValue(
        ':quantity',
        isset($data->quantity)
            ? (int) $data->quantity
            : 1,
        PDO::PARAM_INT
    );

    $stmt->bindValue(
        ':system',
        $data->system ?? ''
    );

    $stmt->bindValue(
        ':tag',
        $data->tag ?? ''
    );

    $stmt->bindValue(
        ':type',
        $data->type ?? ''
    );

    $stmt->bindValue(
        ':asset_name',
        trim($data->asset_name)
    );

    $stmt->bindValue(
        ':group_name',
        $data->group_name ?? ''
    );

    $stmt->bindValue(
        ':classification',
        $data->classification ?? ''
    );

    $stmt->bindValue(
        ':asset_condition',
        $data->asset_condition ?? ''
    );

    $stmt->bindValue(
        ':product_code',
        $data->product_code ?? ''
    );

    $stmt->bindValue(
        ':model_type',
        $data->model_type ?? ''
    );

    $stmt->bindValue(
        ':manufacturer',
        $data->manufacturer ?? ''
    );

    // ========================================================
    // DATES
    // ========================================================

    $stmt->bindValue(
        ':purchase_date',
        $data->purchase_date ?? null
    );

    $stmt->bindValue(
        ':warranty_expiry_date',
        $warrantyExpiry
    );

    // ========================================================
    // PURCHASE
    // ========================================================

    $stmt->bindValue(
        ':purchase_cost',
        $data->purchase_cost ?? 0
    );

    $stmt->bindValue(
        ':supplier',
        $data->supplier ?? ''
    );

    $stmt->bindValue(
        ':cost_center',
        $data->cost_center ?? ''
    );

    // ========================================================
    // OTHER
    // ========================================================

    $stmt->bindValue(
        ':comments',
        $data->comments ?? ''
    );

    $stmt->bindValue(
        ':status',
        $data->status ?? 'ACTIVE'
    );

    // ========================================================
    // VISUAL INSPECTION
    // ========================================================

    $stmt->bindValue(
        ':visual_inspection',
        $data->visual_inspection ?? null
    );

    // ========================================================
    // IMAGE
    // ========================================================

    $stmt->bindValue(
        ':image_base64',
        $data->image_base64 ?? null
    );

    $stmt->bindValue(
        ':image_name',
        $data->image_name ?? null
    );

    $stmt->bindValue(
        ':image_taken_at',
        $imageTakenAt
    );

    // ========================================================
    // INSTALLED TIME
    // ========================================================

    $installedTime = !empty($data->installed_time)
        ? $data->installed_time
        : date('H:i:s');

    $stmt->bindValue(
        ':installed_time',
        $installedTime
    );

    // ========================================================
    // CREATED BY
    // IMPORTANT:
    // This comes ONLY from JWT.
    // Do NOT take created_by from Flutter request.
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
    // INSERTED ASSET ID
    // ========================================================

    $assetId = $conn->lastInsertId();

    // ========================================================
    // SUCCESS
    // ========================================================

    http_response_code(201);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Asset created successfully.",
        "asset_id" => (int) $assetId,
        "created_by" => $userId
    ]);

} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => $e->getMessage(),
        "error_code" => $e->getCode()
    ]);

    error_log(
        "Asset Create Error: " .
        $e->getMessage()
    );

    exit;

}
