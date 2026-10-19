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

if ($id <= 0) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Valid ID is required."
    ]);

    exit;
}

try {

    $query = "
        DELETE FROM dropdown_options
        WHERE id = :id
    ";

    $stmt = $conn->prepare($query);

    $stmt->bindValue(
        ':id',
        $id,
        PDO::PARAM_INT
    );

    $stmt->execute();

    if ($stmt->rowCount() === 0) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Dropdown option not found."
        ]);

        exit;
    }

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Dropdown option deleted successfully."
    ]);
} catch (PDOException $e) {

    error_log(
        "Dropdown Delete Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Unable to delete dropdown option."
    ]);
}
