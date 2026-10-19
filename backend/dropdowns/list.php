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
        "status" => "error",
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

    error_log(
        "Dropdown Authentication Error: " . $e->getMessage()
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
// GET PARAMETERS
// ============================================================

$category = isset($_GET['category'])
    ? trim($_GET['category'])
    : '';

$search = isset($_GET['search'])
    ? trim($_GET['search'])
    : '';

$page = isset($_GET['page'])
    ? (int)$_GET['page']
    : 1;

$limit = isset($_GET['limit'])
    ? (int)$_GET['limit']
    : 10;


// ============================================================
// VALIDATE PAGINATION
// ============================================================

if ($page < 1) {
    $page = 1;
}

if ($limit < 1) {
    $limit = 10;
}

if ($limit > 100) {
    $limit = 100;
}

$offset = ($page - 1) * $limit;


// ============================================================
// GET DROPDOWN OPTIONS
// ============================================================

try {

    // ========================================================
    // WHERE CONDITIONS
    // ========================================================

    $where = [];

    $params = [];


    // ========================================================
    // CATEGORY FILTER
    // ========================================================

    if (
        $category !== '' &&
        strtolower($category) !== 'all'
    ) {

        $where[] = "category = :category";

        $params[':category'] = $category;
    }


    // ========================================================
    // SEARCH FILTER
    // ========================================================

    if ($search !== '') {

        $where[] = "
            (
                category LIKE :search
                OR label LIKE :search
                OR value LIKE :search
            )
        ";

        $params[':search'] = '%' . $search . '%';
    }


    // ========================================================
    // BUILD WHERE SQL
    // ========================================================

    $whereSql = '';

    if (!empty($where)) {

        $whereSql = 'WHERE ' . implode(
            ' AND ',
            $where
        );
    }


    // ========================================================
    // TOTAL COUNT
    // ========================================================

    $countQuery = "
        SELECT COUNT(*) AS total
        FROM dropdown_options
        $whereSql
    ";

    $countStmt = $conn->prepare($countQuery);

    foreach ($params as $key => $value) {

        $countStmt->bindValue(
            $key,
            $value,
            PDO::PARAM_STR
        );
    }

    $countStmt->execute();

    $total = (int)$countStmt
        ->fetch(PDO::FETCH_ASSOC)['total'];


    // ========================================================
    // TOTAL PAGES
    // ========================================================

    $totalPages = $total > 0
        ? (int)ceil($total / $limit)
        : 1;


    // ========================================================
    // GET DATA
    // ========================================================

    $query = "
        SELECT
            id,
            category,
            label,
            value
        FROM dropdown_options
        $whereSql
        ORDER BY category ASC, label ASC
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $conn->prepare($query);


    // ========================================================
    // BIND FILTER PARAMETERS
    // ========================================================

    foreach ($params as $key => $value) {

        $stmt->bindValue(
            $key,
            $value,
            PDO::PARAM_STR
        );
    }


    // ========================================================
    // BIND PAGINATION
    // ========================================================

    $stmt->bindValue(
        ':limit',
        $limit,
        PDO::PARAM_INT
    );

    $stmt->bindValue(
        ':offset',
        $offset,
        PDO::PARAM_INT
    );


    // ========================================================
    // EXECUTE
    // ========================================================

    $stmt->execute();


    // ========================================================
    // FETCH DATA
    // ========================================================

    $options = $stmt->fetchAll(PDO::FETCH_ASSOC);


    // ========================================================
    // GET ALL CATEGORIES
    // ========================================================

    $categoryQuery = "
        SELECT DISTINCT category
        FROM dropdown_options
        ORDER BY category ASC
    ";

    $categoryStmt = $conn->prepare(
        $categoryQuery
    );

    $categoryStmt->execute();

    $categoryRows = $categoryStmt->fetchAll(
        PDO::FETCH_COLUMN
    );


    // ========================================================
    // SUCCESS RESPONSE
    // ========================================================

    http_response_code(200);

    echo json_encode([

        "success" => true,

        "status" => "success",

        "message" =>
        "Dropdown options retrieved successfully.",

        "user_id" => $userId,

        "data" => $options,

        "categories" => $categoryRows,

        "pagination" => [

            "page" => $page,

            "limit" => $limit,

            "total" => $total,

            "total_pages" => $totalPages

        ]

    ]);


    // ============================================================
    // DATABASE ERROR
    // ============================================================

} catch (PDOException $e) {

    error_log(
        "Dropdown DB Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "status" => "error",

        "message" =>
        "Unable to retrieve dropdown options."

    ]);
}
