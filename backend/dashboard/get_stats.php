<?php

// ============================================================
// REQUIRED FILES
// ============================================================

require_once __DIR__ . '/../db_connection.php';
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

    http_response_code(401);

    echo json_encode([
        "success" => false,
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
        "message" => "User ID not found in token."
    ]);

    exit;
}

$userId = (int)$decoded->user_id;


// ============================================================
// DASHBOARD SUMMARY
// ============================================================

try {

    /*
     * --------------------------------------------------------
     * Asset Type Summary
     * --------------------------------------------------------
     *
     * Only assets created by the logged-in user are counted.
     *
     * DELETED assets are excluded.
     *
     * quantity is summed instead of counting rows.
     *
     */

    $query = "
        SELECT
            t.name AS asset_class,

            UPPER(LEFT(t.name, 3)) AS class_code,

            IFNULL(SUM(
                CASE
                    WHEN a.status != 'DELETED'
                    THEN a.quantity
                    ELSE 0
                END
            ), 0) AS total_assets

        FROM asset_types t

        LEFT JOIN assets a
            ON t.name = a.type
            AND a.created_by = :created_by

        GROUP BY
            t.id,
            t.name

        ORDER BY
            total_assets DESC
    ";


    $stmt = $conn->prepare($query);

    $stmt->bindValue(
        ':created_by',
        $userId,
        PDO::PARAM_INT
    );

    $stmt->execute();


    $stats = $stmt->fetchAll(PDO::FETCH_ASSOC);


    // ========================================================
    // FORMAT NUMERIC VALUES
    // ========================================================

    foreach ($stats as &$row) {

        $row['total_assets'] = (int)$row['total_assets'];
    }

    unset($row);


    // ========================================================
    // SUCCESS RESPONSE
    // ========================================================

    http_response_code(200);

    echo json_encode([

        "success" => true,

        "status" => "success",

        "message" => "Dashboard statistics retrieved successfully.",

        "user_id" => $userId,

        "data" => $stats

    ]);
} catch (PDOException $e) {

    // ========================================================
    // DATABASE ERROR
    // ========================================================

    error_log(
        "Dashboard Statistics DB Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "status" => "error",

        "message" => "Unable to retrieve dashboard statistics."

    ]);
}
