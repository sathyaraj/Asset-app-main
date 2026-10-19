<?php

// ============================================================
// CORS
// ============================================================

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");


// ============================================================
// HANDLE OPTIONS REQUEST
// ============================================================

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(200);
    exit;
}


// ============================================================
// ONLY PUT METHOD
// ============================================================

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'PUT') {

    http_response_code(405);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Only PUT method is allowed.'
    ]);

    exit;
}


// ============================================================
// LOAD REQUIRED FILES
// ============================================================

require_once __DIR__ . '/../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';


// ============================================================
// GET AUTHORIZATION HEADER
// ============================================================

$headers = getallheaders();

$authorization = '';

if (isset($headers['Authorization'])) {

    $authorization = $headers['Authorization'];

} elseif (isset($headers['authorization'])) {

    $authorization = $headers['authorization'];
}


// ============================================================
// CHECK AUTHORIZATION HEADER
// ============================================================

if (empty($authorization)) {

    http_response_code(401);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Authorization token is required.'
    ]);

    exit;
}


// ============================================================
// CHECK BEARER TOKEN FORMAT
// ============================================================

if (!preg_match('/Bearer\s+(.+)/i', $authorization, $matches)) {

    http_response_code(401);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Invalid authorization format.'
    ]);

    exit;
}

$jwt = trim($matches[1]);


// ============================================================
// READ JSON REQUEST
// ============================================================

$input = json_decode(
    file_get_contents("php://input"),
    true
);


if (!is_array($input)) {

    http_response_code(400);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Invalid JSON request.'
    ]);

    exit;
}


// ============================================================
// GET INPUT VALUES
// ============================================================

$userId = isset($input['id'])
    ? (int) $input['id']
    : 0;

$fullName = trim($input['full_name'] ?? '');

$employeeId = trim($input['employee_id'] ?? '');

$email = trim($input['email'] ?? '');

$phone = trim($input['phone'] ?? '');

$department = trim($input['department'] ?? '');

$designation = trim($input['designation'] ?? '');

$employeeType = trim($input['employee_type'] ?? '');

$location = trim($input['location'] ?? '');

$role = trim($input['role'] ?? '');

$status = trim($input['status'] ?? '');


// ============================================================
// VALIDATION
// ============================================================

if ($userId <= 0) {

    http_response_code(400);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Valid user ID is required.'
    ]);

    exit;
}


if ($fullName === '') {

    http_response_code(400);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Full name is required.'
    ]);

    exit;
}


if ($employeeId === '') {

    http_response_code(400);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Employee ID is required.'
    ]);

    exit;
}


if ($email === '') {

    http_response_code(400);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Email is required.'
    ]);

    exit;
}


if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {

    http_response_code(400);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Invalid email address.'
    ]);

    exit;
}


if ($role === '') {

    http_response_code(400);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Role is required.'
    ]);

    exit;
}


if (!in_array($status, ['active', 'inactive'], true)) {

    http_response_code(400);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Invalid status.'
    ]);

    exit;
}


// ============================================================
// CHECK USER EXISTS
// ============================================================

$stmt = $conn->prepare("
    SELECT id
    FROM emp_users
    WHERE id = :id
    LIMIT 1
");

$stmt->execute([
    ':id' => $userId
]);

$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {

    http_response_code(404);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'User not found.'
    ]);

    exit;
}


// ============================================================
// CHECK DUPLICATE EMPLOYEE ID
// ============================================================

$stmt = $conn->prepare("
    SELECT id
    FROM emp_users
    WHERE employee_id = :employee_id
      AND id != :id
    LIMIT 1
");

$stmt->execute([
    ':employee_id' => $employeeId,
    ':id' => $userId
]);

$duplicateEmployee = $stmt->fetch(PDO::FETCH_ASSOC);

if ($duplicateEmployee) {

    http_response_code(409);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Employee ID already exists.'
    ]);

    exit;
}


// ============================================================
// CHECK DUPLICATE EMAIL
// ============================================================

$stmt = $conn->prepare("
    SELECT id
    FROM emp_users
    WHERE LOWER(email) = LOWER(:email)
      AND id != :id
    LIMIT 1
");

$stmt->execute([
    ':email' => $email,
    ':id' => $userId
]);

$duplicateEmail = $stmt->fetch(PDO::FETCH_ASSOC);

if ($duplicateEmail) {

    http_response_code(409);

    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Email address already exists.'
    ]);

    exit;
}


// ============================================================
// UPDATE USER
// ============================================================

$stmt = $conn->prepare("
    UPDATE emp_users
    SET
        full_name = :full_name,
        employee_id = :employee_id,
        email = :email,
        phone = :phone,
        department = :department,
        designation = :designation,
        employee_type = :employee_type,
        location = :location,
        role = :role,
        status = :status
    WHERE id = :id
");


// ============================================================
// EXECUTE UPDATE
// ============================================================

$stmt->execute([
    ':full_name' => $fullName,
    ':employee_id' => $employeeId,
    ':email' => $email,
    ':phone' => $phone,
    ':department' => $department,
    ':designation' => $designation,
    ':employee_type' => $employeeType,
    ':location' => $location,
    ':role' => $role,
    ':status' => $status,
    ':id' => $userId
]);


// ============================================================
// SUCCESS RESPONSE
// ============================================================

http_response_code(200);

echo json_encode([
    'success' => true,
    'status' => 'success',
    'message' => 'User updated successfully.',
    'user' => [
        'id' => $userId,
        'full_name' => $fullName,
        'employee_id' => $employeeId,
        'email' => $email,
        'phone' => $phone,
        'department' => $department,
        'designation' => $designation,
        'employee_type' => $employeeType,
        'location' => $location,
        'role' => $role,
        'status' => $status
    ]
]);


// ============================================================
// CLOSE CONNECTION
// ============================================================

$conn = null;

?>
