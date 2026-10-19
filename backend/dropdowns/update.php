<?php

require_once '../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Only PUT method is allowed."
    ]);

    exit;
}

try {

    authenticate();

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

$id = isset($input['id'])
    ? (int)$input['id']
    : 0;

$category = trim($input['category'] ?? '');
$label = trim($input['label'] ?? '');
$value = trim($input['value'] ?? '');

if ($id <= 0) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Valid ID is required."
    ]);

    exit;
}

if ($category === '' || $label === '' || $value === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Category, label and value are required."
    ]);

    exit;
}

try {

    $checkQuery = "
        SELECT id
        FROM dropdown_options
        WHERE id = :id
        LIMIT 1
    ";

    $checkStmt = $conn->prepare($checkQuery);

    $checkStmt->bindValue(
        ':id',
        $id,
        PDO::PARAM_INT
    );

    $checkStmt->execute();

    if (!$checkStmt->fetch()) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Dropdown option not found."
        ]);

        exit;
    }


    $query = "
        UPDATE dropdown_options
        SET
            category = :category,
            label = :label,
            value = :value
        WHERE id = :id
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

    $stmt->bindValue(
        ':id',
        $id,
        PDO::PARAM_INT
    );

    $stmt->execute();

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Dropdown option updated successfully."
    ]);

} catch (PDOException $e) {

    error_log(
        "Dropdown Update Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unable to update dropdown option."
    ]);
}