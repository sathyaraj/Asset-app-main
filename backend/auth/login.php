<?php

// ============================================================
// REQUIRED FILES
// ============================================================

require_once '../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

use Firebase\JWT\JWT;

// ============================================================
// HEADERS
// ============================================================

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// ============================================================
// OPTIONS REQUEST
// ============================================================

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {

    http_response_code(200);
    exit;
}

// ============================================================
// ONLY POST METHOD ALLOWED
// ============================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {

    http_response_code(405);

    echo json_encode([
        "success" => false,
        "message" => "Only POST method is allowed."
    ]);

    exit;
}

// ============================================================
// READ JSON INPUT
// ============================================================

// $input = file_get_contents("php://input");

// $data = json_decode($input);

// if ($data === null) {

//     http_response_code(400);

//     echo json_encode([
//         "success" => false,
//         "message" => "Invalid JSON data."
//     ]);

//     exit;
// }

// ============================================================
// GET LOGIN DATA
// ============================================================


// $email = trim($data->email ?? '');

// $username = trim($data->username ?? '');

// $password = $data->password ?? '';


 // ============================================================
 // READ JSON INPUT
 // ============================================================

$input = file_get_contents("php://input");

try {
    $data = json_decode(
        $input,
        false,
        512,
        JSON_THROW_ON_ERROR
    );
} catch (\JsonException $e) {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid JSON data."
    ]);

    exit;
}

if (!is_object($data)) {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "JSON input must be an object."
    ]);

    exit;
}

// ============================================================
// GET LOGIN DATA
// ============================================================

$email = trim((string)($data->email ?? ''));

$username = trim((string)($data->username ?? ''));

$password = $data->password ?? '';

if (!is_string($password) || $password === '') {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Password is required."
    ]);

    exit;
}



// ============================================================
// VALIDATE PASSWORD
// ============================================================

if ($password === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Password is required."
    ]);

    exit;
}

// ============================================================
// VALIDATE EMAIL / USERNAME
// ============================================================

if ($email === '' && $username === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Email or username is required."
    ]);

    exit;
}

// ============================================================
// LOGIN
// ============================================================

try {

    // ========================================================
    // LOGIN USING EMAIL
    // ========================================================

    if ($email !== '') {

        $query = "
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
                status,
                username,
                password_hash
            FROM emp_users
            WHERE email = ?
            LIMIT 1
        ";

        $stmt = $conn->prepare($query);

        $stmt->execute([
            $email
        ]);
    }

    // ========================================================
    // LOGIN USING USERNAME
    // ========================================================

    else {

        $query = "
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
                status,
                username,
                password_hash
            FROM emp_users
            WHERE username = ?
            LIMIT 1
        ";

        $stmt = $conn->prepare($query);

        $stmt->execute([
            $username
        ]);
    }

    // ========================================================
    // GET USER
    // ========================================================

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // ========================================================
    // USER NOT FOUND
    // ========================================================

    if (!$user) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Invalid email/username or password."
        ]);

        exit;
    }

    // ========================================================
    // CHECK LOGIN ACCESS
    // ========================================================

    if ((int)$user['login_access'] !== 1) {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "message" => "Login access is disabled for this user.",
            "status" => $user['status']
        ]);

        exit;
    }

    // ========================================================
    // CHECK USER STATUS
    // ========================================================

    $userStatus = strtolower(trim($user['status'] ?? ''));

    if ($userStatus !== 'active') {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "message" => "Your account is not active. Please contact administrator.",
            "status" => $user['status']
        ]);

        exit;
    }

    // ========================================================
    // CHECK PASSWORD
    // ========================================================

    if (
        empty($user['password_hash']) ||
        !password_verify($password, $user['password_hash'])
    ) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Invalid email/username or password."
        ]);

        exit;
    }

    // ========================================================
    // JWT TIMESTAMPS
    // ========================================================

    $issuedAt = time();

    $expiration = $issuedAt + JWT_EXPIRATION;

    // ========================================================
    // JWT PAYLOAD
    // ========================================================

    $payload = [

        // ----------------------------------------------------
        // STANDARD JWT CLAIMS
        // ----------------------------------------------------

        "iss" => JWT_ISSUER,

        "iat" => $issuedAt,

        "exp" => $expiration,

        // ----------------------------------------------------
        // USER INFORMATION
        // ----------------------------------------------------

        "user_id" => (int)$user['id'],

        "employee_id" => $user['employee_id'],

        "email" => $user['email'],

        "username" => $user['username'],

        "role" => $user['role'],

        "status" => $user['status']
    ];

    // ========================================================
    // GENERATE JWT TOKEN
    // ========================================================

    $token = JWT::encode(
        $payload,
        JWT_SECRET,
        'HS256'
    );

    // ========================================================
    // SUCCESS RESPONSE
    // ========================================================

    http_response_code(200);

    echo json_encode([

        "success" => true,

        "message" => "Login successful.",

        // ----------------------------------------------------
        // JWT
        // ----------------------------------------------------

        "token" => $token,

        "token_type" => "Bearer",

        "expires_in" => JWT_EXPIRATION,

        // ----------------------------------------------------
        // USER
        // ----------------------------------------------------

        "user" => [

            "id" => (int)$user['id'],

            "full_name" => $user['full_name'],

            "employee_id" => $user['employee_id'],

            "email" => $user['email'],

            "username" => $user['username'],

            "phone" => $user['phone'],

            "country_code" => $user['country_code'],

            "department" => $user['department'],

            "designation" => $user['designation'],

            "employee_type" => $user['employee_type'],

            "date_of_birth" => $user['date_of_birth'],

            "location" => $user['location'],

            "role" => $user['role'],

            "status" => $user['status']
        ]
    ]);
} catch (PDOException $e) {

    // ========================================================
    // DATABASE ERROR
    // ========================================================

    error_log(
        "Login DB Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Database error. Please try again later."
    ]);
} catch (Exception $e) {

    // ========================================================
    // GENERAL ERROR
    // ========================================================

    error_log(
        "Login Error: " . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to login. Please try again later."
    ]);
}
