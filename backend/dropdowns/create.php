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

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Only POST method is allowed."
    ]);

    exit;
}

try {

    $decoded = authenticate();

} catch (Exception $e) {

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unauthorized. Invalid or expired token."
    ]);

    exit;
}

$input = json_decode(
    file_get_contents("php://input"),
    true
);

$category = trim($input['category'] ?? '');
$label = trim($input['label'] ?? '');
$value = trim($input['value'] ?? '');

if ($category === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Category is required."
    ]);

    exit;
}

if ($label === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Label is required."
    ]);

    exit;
}

if ($value === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Value is required."
    ]);

    exit;
}

try {

    $query = "
        INSERT INTO dropdown_options
        (
            category,
            label,
            value
        )
        VALUES
        (
            :category,
            :label,
            :value
        )
    ";

    $stmt = $conn->prepare($query);

    $stmt->bindValue(
        ':category',
        $category,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ':label',
        $label,
        PDO::PARAM_STR
    );

    $stmt->bindValue(
        ':value',
        $value,
        PDO::PARAM_STR
    );

    $stmt->execute();

    $id = (int)$conn->lastInsertId();

    http_response_code(201);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Dropdown option created successfully.",
        "data" => [
            "id" => $id,
            "category" => $category,
            "label" => $label,
            "value" => $value
        ]
    ]);

} catch (PDOException $e) {

    error_log(
        "Dropdown Create Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unable to create dropdown option."
    ]);
}