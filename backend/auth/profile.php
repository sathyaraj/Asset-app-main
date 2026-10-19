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
// HANDLE OPTIONS REQUEST
// ============================================================

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}


// ============================================================
// ONLY GET METHOD ALLOWED
// ============================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "message" => "Method not allowed."
    ]);

    exit;
}


// ============================================================
// AUTHENTICATE USER
// ============================================================

$decoded = authenticate();


// ============================================================
// GET USER ID FROM JWT
// ============================================================

$userId = isset($decoded->user_id)
    ? (int) $decoded->user_id
    : 0;


// ============================================================
// VALIDATE USER ID
// ============================================================

if ($userId <= 0) {

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "message" => "Invalid user information in token."
    ]);

    exit;
}


try {

    // ========================================================
    // GET USER PROFILE
    // ========================================================

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
        WHERE id = :id
        LIMIT 1
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ':id' => $userId
    ]);

    $user = $stmt->fetch(PDO::FETCH_ASSOC);


    // ========================================================
    // USER NOT FOUND
    // ========================================================

    if (!$user) {

        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "User not found."
        ]);

        exit;
    }


    // ========================================================
    // CHECK LOGIN ACCESS
    // ========================================================

    if ((int) $user['login_access'] !== 1) {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "message" => "Login access has been disabled."
        ]);

        exit;
    }


    // ========================================================
    // GET SETTINGS PAGE PERMISSION DYNAMICALLY
    // ========================================================
    //
    // IMPORTANT:
    // No hardcoded page_id is used here.
    //
    // Role comes dynamically from emp_users.role.
    //
    // page_id is found dynamically through pages table.
    //
    // ========================================================

    $pageName = 'Profile';


    $permissionSql = "
        SELECT
            p.id AS page_id,
            p.page_name,
            p.page_key,
            rpp.can_view,
            rpp.can_create,
            rpp.can_update,
            rpp.can_delete
        FROM role_page_permissions rpp

        INNER JOIN pages p
            ON p.id = rpp.page_id

        WHERE rpp.role = :role

          AND LOWER(TRIM(p.page_name))
              = LOWER(TRIM(:page_name))

          AND p.is_active = 1

        LIMIT 1
    ";


    $permissionStmt = $conn->prepare($permissionSql);



    // ========================================================
    // ROLE IS DYNAMIC
    // ========================================================

    $permissionStmt->execute([
        ':role' => $user['role'],
        ':page_name' => $pageName
    ]);


    $permission = $permissionStmt->fetch(PDO::FETCH_ASSOC);


    // ========================================================
    // DEFAULT PERMISSIONS
    // ========================================================

    $user['can_view'] = 0;
    $user['can_create'] = 0;
    $user['can_update'] = 0;
    $user['can_delete'] = 0;


    // ========================================================
    // APPLY PERMISSIONS IF FOUND
    // ========================================================

    if ($permission) {

        $user['can_view'] = (int) $permission['can_view'];

        $user['can_create'] = (int) $permission['can_create'];

        $user['can_update'] = (int) $permission['can_update'];

        $user['can_delete'] = (int) $permission['can_delete'];
    }


    // ========================================================
    // REMOVE INTERNAL LOGIN ACCESS FIELD
    // ========================================================

    unset($user['login_access']);


    // ========================================================
    // SUCCESS RESPONSE
    // ========================================================

    echo json_encode([
        "success" => true,
        "message" => "Profile retrieved successfully.",
        "user" => $user
    ]);
} catch (PDOException $e) {

    // ========================================================
    // DATABASE ERROR
    // ========================================================

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve profile."
    ]);
}
