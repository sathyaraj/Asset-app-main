<?php

require_once '../db_connection.php';
require_once '../vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

header('Content-Type: application/json');

// =====================================================
// JWT CONFIG
// =====================================================

$jwtSecret = 'YOUR_SECRET_KEY_HERE';

// =====================================================
// AUTHENTICATION
// =====================================================

function authenticateJWT($jwtSecret)
{
    $headers = getallheaders();

    $authHeader = '';

    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
    } elseif (isset($headers['authorization'])) {
        $authHeader = $headers['authorization'];
    }

    if (empty($authHeader)) {
        http_response_code(401);

        echo json_encode([
            "status" => "error",
            "message" => "Authorization token is required"
        ]);

        exit;
    }

    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        http_response_code(401);

        echo json_encode([
            "status" => "error",
            "message" => "Invalid authorization format"
        ]);

        exit;
    }

    $jwt = $matches[1];

    try {

        $decoded = JWT::decode(
            $jwt,
            new Key($jwtSecret, 'HS256')
        );

        return $decoded;
    } catch (Exception $e) {

        http_response_code(401);

        echo json_encode([
            "status" => "error",
            "message" => "Invalid or expired token"
        ]);

        exit;
    }
}

// =====================================================
// VERIFY JWT
// =====================================================

$user = authenticateJWT($jwtSecret);

// =====================================================
// CODE VALIDATION
// =====================================================

try {

    if (empty($_GET['code'])) {

        http_response_code(400);

        echo json_encode([
            "status" => "error",
            "message" => "Code is required"
        ]);

        exit;
    }

    $code = trim($_GET['code']);

    // =================================================
    // 1. SEARCH ASSET
    // =================================================

    $assetSql = "
        SELECT *
        FROM assets
        WHERE asset_code = :code
        LIMIT 1
    ";

    $assetStmt = $conn->prepare($assetSql);

    $assetStmt->bindParam(':code', $code);

    $assetStmt->execute();

    $asset = $assetStmt->fetch(PDO::FETCH_ASSOC);

    if ($asset) {

        echo json_encode([
            "status" => "success",
            "type" => "asset",
            "message" => "Asset found",
            "data" => $asset
        ]);

        exit;
    }

    // =================================================
    // 2. SEARCH LOCATION
    // =================================================

    $locationSql = "
        SELECT *
        FROM locations
        WHERE code = :code
        LIMIT 1
    ";

    $locationStmt = $conn->prepare($locationSql);

    $locationStmt->bindParam(':code', $code);

    $locationStmt->execute();

    $location = $locationStmt->fetch(PDO::FETCH_ASSOC);

    if ($location) {

        echo json_encode([
            "status" => "success",
            "type" => "location",
            "message" => "Location found",
            "data" => $location
        ]);

        exit;
    }

    // =================================================
    // 3. NOT FOUND
    // =================================================

    http_response_code(404);

    echo json_encode([
        "status" => "error",
        "message" => "No Asset or Location found for code: " . $code
    ]);
} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([
        "status" => "error",
        "message" => "Database server error"
    ]);
}
