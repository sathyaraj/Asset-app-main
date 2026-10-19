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
// IMPORTANT:
// Same as your create.php
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

$data = json_decode($rawData, true);

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
// CHECK ASSETS ARRAY
// ============================================================

if (
    !isset($data['assets']) ||
    !is_array($data['assets'])
) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Assets array is required."
    ]);

    exit;
}

$assets = $data['assets'];

if (empty($assets)) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "No assets provided."
    ]);

    exit;
}

// ============================================================
// START TRANSACTION
// ============================================================

try {

    $conn->beginTransaction();

    // ========================================================
    // INSERT SQL
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

            :installed_time,

            :created_by

        )
    ";

    // ========================================================
    // PREPARE
    // ========================================================

    $stmt = $conn->prepare($sql);

    $successCount = 0;
    $errors = [];

    // ========================================================
    // LOOP ASSETS
    // ========================================================

    foreach ($assets as $index => $asset) {

        try {

            // ==================================================
            // REQUIRED FIELDS
            // ==================================================

            if (
                empty($asset['asset_name']) ||
                empty($asset['asset_code'])
            ) {

                throw new Exception(
                    "Asset name and asset code are required."
                );
            }

            // ==================================================
            // LOCATION
            // ==================================================

            $locationId = $asset['location_id']
                ?? $asset['location']
                ?? null;

            if (
                $locationId !== null &&
                $locationId !== '' &&
                !is_numeric($locationId)
            ) {
                $locationId = null;
            }

            // ==================================================
            // WARRANTY EXPIRY
            // ==================================================

            $warrantyExpiry = null;

            if (!empty($asset['warranty_expiry_date'])) {

                $timestamp = strtotime(
                    $asset['warranty_expiry_date']
                );

                if ($timestamp !== false) {

                    $warrantyExpiry = date(
                        'Y-m-d',
                        $timestamp
                    );
                }
            }

            // ==================================================
            // INSTALLED TIME
            // ==================================================

            $installedTime = !empty($asset['installed_time'])
                ? $asset['installed_time']
                : date('H:i:s');

            // ==================================================
            // EXECUTE
            // ==================================================

            $stmt->execute([

                ':location_id' =>
                $locationId !== null &&
                    $locationId !== ''
                    ? (int) $locationId
                    : null,

                ':asset_code' =>
                trim($asset['asset_code']),

                ':description' =>
                $asset['description'] ?? '',

                ':quantity' =>
                isset($asset['quantity'])
                    ? (int) $asset['quantity']
                    : 1,

                ':system' =>
                $asset['system'] ?? '',

                ':tag' =>
                $asset['tag'] ?? '',

                ':type' =>
                $asset['type'] ?? '',

                ':asset_name' =>
                trim($asset['asset_name']),

                ':group_name' =>
                $asset['group_name'] ?? '',

                ':classification' =>
                $asset['classification'] ?? '',

                ':asset_condition' =>
                $asset['asset_condition'] ?? '',

                ':product_code' =>
                $asset['product_code'] ?? '',

                ':model_type' =>
                $asset['model_type'] ?? '',

                ':manufacturer' =>
                $asset['manufacturer'] ?? '',

                ':purchase_date' =>
                $asset['purchase_date'] ?? null,

                ':warranty_expiry_date' =>
                $warrantyExpiry,

                ':purchase_cost' =>
                $asset['purchase_cost'] ?? 0,

                ':supplier' =>
                $asset['supplier'] ?? '',

                ':cost_center' =>
                $asset['cost_center'] ?? '',

                ':comments' =>
                $asset['comments'] ?? '',

                ':status' =>
                $asset['status'] ?? 'ACTIVE',

                ':installed_time' =>
                $installedTime,

                // ==============================================
                // IMPORTANT
                // JWT USER ID
                // ==============================================

                ':created_by' =>
                $userId
            ]);

            $successCount++;
        } catch (Exception $e) {

            $errors[] = [

                "row" => $index + 2,

                "asset_code" =>
                $asset['asset_code'] ?? null,

                "message" =>
                $e->getMessage()
            ];
        }
    }

    // ========================================================
    // COMMIT
    // ========================================================

    $conn->commit();

    // ========================================================
    // RESPONSE
    // ========================================================

    http_response_code(200);

    echo json_encode([

        "success" => true,

        "status" => "success",

        "message" =>
        "Bulk asset import completed.",

        "total" =>
        count($assets),

        "success_count" =>
        $successCount,

        "failure_count" =>
        count($errors),

        "created_by" =>
        $userId,

        "errors" =>
        $errors
    ]);
} catch (Exception $e) {

    // ========================================================
    // ROLLBACK
    // ========================================================

    if ($conn->inTransaction()) {
        $conn->rollBack();
    }

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "status" => "error",

        "message" =>
        "Bulk asset import failed."
    ]);
}
