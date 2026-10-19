<?php

require_once '../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// ----------------------------------------
// OPTIONS
// ----------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ----------------------------------------
// GET only
// ----------------------------------------
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "message" => "Method not allowed."
    ]);

    exit;
}

// ----------------------------------------
// JWT Authentication
// ----------------------------------------
$decoded = authenticate();

// ----------------------------------------
// Get logged-in user ID
// ----------------------------------------
$currentUserId = isset($decoded->user_id)
    ? (int)$decoded->user_id
    : 0;

if ($currentUserId <= 0) {

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "message" => "Invalid user information in token."
    ]);

    exit;
}

try {

    // ----------------------------------------
    // Query Parameters
    // ----------------------------------------
    $search = trim($_GET['search'] ?? '');
    $role = trim($_GET['role'] ?? '');
    $department = trim($_GET['department'] ?? '');
    $status = trim($_GET['status'] ?? '');

    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = min(100, max(1, (int)($_GET['limit'] ?? 10)));

    $offset = ($page - 1) * $limit;

    // ----------------------------------------
    // WHERE
    // ----------------------------------------
    $where = [];
    $params = [];

    // Search
    if ($search !== '') {

        $where[] = "
            (
                full_name LIKE :search
                OR employee_id LIKE :search
                OR username LIKE :search
                OR email LIKE :search
                OR phone LIKE :search
            )
        ";

        $params[':search'] = "%{$search}%";
    }

    // Role
    if ($role !== '') {

        $where[] = "role = :role";

        $params[':role'] = $role;
    }

    // Department
    if ($department !== '') {

        $where[] = "department = :department";

        $params[':department'] = $department;
    }

    // Status
    if ($status !== '') {

        if ($status === 'active') {

            $where[] = "login_access = 1";

        } elseif ($status === 'inactive') {

            $where[] = "login_access = 0";
        }
    }

    $whereSql = '';

    if (count($where) > 0) {
        $whereSql = 'WHERE ' . implode(' AND ', $where);
    }

    // ----------------------------------------
    // Total Count
    // ----------------------------------------
    $countSql = "
        SELECT COUNT(*) 
        FROM emp_users
        {$whereSql}
    ";

    $countStmt = $conn->prepare($countSql);
    $countStmt->execute($params);

    $total = (int)$countStmt->fetchColumn();

    // ----------------------------------------
    // Get Users
    // ----------------------------------------
    $sql = "
        SELECT
            id,
            full_name,
            employee_id,
            email,
            phone,
            country_code,
            department,
            designation,
            employee_type,
            date_of_birth,
            location,
            role,
            login_access,
            username
        FROM emp_users
        {$whereSql}
        ORDER BY id DESC
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $conn->prepare($sql);

    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }

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

    $stmt->execute();

    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // ----------------------------------------
    // Format Response
    // ----------------------------------------
    foreach ($users as &$user) {

        $user['id'] = (int)$user['id'];

        $user['login_access'] =
            (int)$user['login_access'];

        $user['status'] =
            ((int)$user['login_access'] === 1)
                ? 'active'
                : 'inactive';

        // Don't expose this field
        unset($user['login_access']);
    }

    // ----------------------------------------
    // Pagination
    // ----------------------------------------
    $totalPages = $limit > 0
        ? (int)ceil($total / $limit)
        : 0;

    // ----------------------------------------
    // Response
    // ----------------------------------------
    echo json_encode([
        "success" => true,
        "message" => "Users retrieved successfully.",
        "data" => [
            "users" => $users,
            "pagination" => [
                "page" => $page,
                "limit" => $limit,
                "total" => $total,
                "total_pages" => $totalPages
            ]
        ]
    ]);

} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve users."
    ]);

    error_log($e->getMessage());
}