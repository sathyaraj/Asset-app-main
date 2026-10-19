<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
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
// ONLY POST ALLOWED
// ============================================================

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);

    echo json_encode([
        "success" => false,
        "message" => "Only POST method is allowed."
    ]);

    exit;
}

// ============================================================
// LOAD REQUIRED FILES
// ============================================================

require_once '../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$mail = new PHPMailer(true);
$mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
// ============================================================
// CHECK DATABASE CONNECTION
// ============================================================

if (!isset($conn) || !$conn instanceof PDO) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Database connection is not available."
    ]);

    exit;
}

// ============================================================
// JWT AUTHENTICATION
// ============================================================

$decoded = authenticate();

// ============================================================
// GET CURRENT USER INFORMATION FROM JWT
// ============================================================

$currentUserId = isset($decoded->user_id)
    ? (int)$decoded->user_id
    : 0;

$currentUserRole = isset($decoded->role)
    ? trim((string)$decoded->role)
    : '';

// ============================================================
// CHECK USER ID
// ============================================================

if ($currentUserId <= 0) {

    http_response_code(401);

    echo json_encode([
        "success" => false,
        "message" => "Invalid user information in token."
    ]);

    exit;
}

// ============================================================
// PAGE PERMISSION
// ============================================================

// try {

//     requirePermission(
//         $conn,
//         $currentUserId,
//         'user_management',
//         'create'
//     );
// } catch (Throwable $e) {

//     error_log(
//         "Create User Permission Error: " . $e->getMessage()
//     );

//     http_response_code(403);

//     echo json_encode([
//         "success" => false,
//         "message" => "You do not have permission to create users."
//     ]);

//     exit;
// }

// ============================================================
// READ JSON REQUEST
// ============================================================

$input = file_get_contents("php://input");

$data = json_decode($input);

if ($data === null) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid JSON data."
    ]);

    exit;
}

// ============================================================
// REQUIRED FIELDS
// ============================================================

$fullName   = trim($data->full_name ?? '');
$employeeId = trim($data->employee_id ?? '');
$email      = trim($data->email ?? '');
$department = trim($data->department ?? '');
$role       = trim($data->role ?? '');

// ============================================================
// LOGIN FIELDS
// ============================================================

$loginAccess = isset($data->login_access)
    ? (bool)$data->login_access
    : false;

$username = trim($data->username ?? '');

$password = $data->password ?? '';

$sendCredentials = isset($data->send_credentials)
    ? (bool)$data->send_credentials
    : false;

// ============================================================
// OPTIONAL FIELDS
// ============================================================

$phone        = trim($data->phone ?? '');
$countryCode  = trim($data->country_code ?? '');
$designation  = trim($data->designation ?? '');
$employeeType = trim($data->employee_type ?? '');
$dateOfBirth  = trim($data->date_of_birth ?? '');
$location     = trim($data->location ?? '');

// ============================================================
// BASIC VALIDATION
// ============================================================

if ($fullName === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Full name is required."
    ]);

    exit;
}

if ($employeeId === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Employee ID is required."
    ]);

    exit;
}

if ($department === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Department is required."
    ]);

    exit;
}

if ($role === '') {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Role is required."
    ]);

    exit;
}

// ============================================================
// EMAIL VALIDATION
// ============================================================

if (
    $email !== ''
    && !filter_var($email, FILTER_VALIDATE_EMAIL)
) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid email address."
    ]);

    exit;
}

// ============================================================
// DYNAMIC USER ROLE VALIDATION
// ============================================================

// $normalizedUserRole = strtolower(trim($role));

// if ($normalizedUserRole === '') {

//     http_response_code(400);

//     echo json_encode([
//         "success" => false,
//         "message" => "User role is required."
//     ]);

//     exit;
// }

// try {

//     $roleStmt = $conn->prepare("
//         SELECT
//             id,
//             name,
//             value,
//             is_active
//         FROM roles
//         WHERE LOWER(value) = LOWER(?)
//           AND is_active = 1
//         LIMIT 1
//     ");

//     $roleStmt->execute([
//         $normalizedUserRole
//     ]);

//     $roleRow = $roleStmt->fetch(PDO::FETCH_ASSOC);

//     if (!$roleRow) {

//         http_response_code(400);

//         echo json_encode([
//             "success" => false,
//             "message" => "Invalid user role.",
//             "role" => $role
//         ]);

//         exit;
//     }

//     $role = trim((string)$roleRow['value']);
// } catch (PDOException $e) {

//     error_log(
//         "Role validation error: " . $e->getMessage()
//     );

//     http_response_code(500);

//     echo json_encode([
//         "success" => false,
//         "message" => "Unable to validate user role."
//     ]);

//     exit;
// }

// ============================================================
// LOGIN VALIDATION
// ============================================================

if ($loginAccess) {

    // --------------------------------------------------------
    // USERNAME
    // --------------------------------------------------------

    if ($username === '') {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" =>
            "Username is required when login access is enabled."
        ]);

        exit;
    }

    if (strlen($username) < 3) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" =>
            "Username must contain at least 3 characters."
        ]);

        exit;
    }

    // --------------------------------------------------------
    // PASSWORD
    // --------------------------------------------------------

    if ($password === '') {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" =>
            "Password is required when login access is enabled."
        ]);

        exit;
    }

    if (strlen($password) < 8) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" =>
            "Password must contain at least 8 characters."
        ]);

        exit;
    }
}

// ============================================================
// DATABASE OPERATIONS
// ============================================================

try {

    // ========================================================
    // CHECK DUPLICATE EMPLOYEE ID
    // ========================================================

    $checkEmployee = $conn->prepare("
        SELECT id
        FROM emp_users
        WHERE employee_id = ?
        LIMIT 1
    ");

    $checkEmployee->execute([
        $employeeId
    ]);

    if ($checkEmployee->fetch(PDO::FETCH_ASSOC)) {

        http_response_code(409);

        echo json_encode([
            "success" => false,
            "message" => "Employee ID already exists."
        ]);

        exit;
    }

    // ========================================================
    // CHECK DUPLICATE EMAIL
    // ========================================================

    if ($email !== '') {

        $checkEmail = $conn->prepare("
            SELECT id
            FROM emp_users
            WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))
            LIMIT 1
        ");

        $checkEmail->execute([
            $email
        ]);

        if ($checkEmail->fetch(PDO::FETCH_ASSOC)) {

            http_response_code(409);

            echo json_encode([
                "success" => false,
                "status" => "error",
                "message" => "Email address already exists.",
                "field" => "email"
            ]);

            exit;
        }
    }

    // ========================================================
    // CHECK DUPLICATE USERNAME
    // ========================================================

    if ($loginAccess) {

        $checkUsername = $conn->prepare("
            SELECT id
            FROM emp_users
            WHERE username = ?
            LIMIT 1
        ");

        $checkUsername->execute([
            $username
        ]);

        if ($checkUsername->fetch(PDO::FETCH_ASSOC)) {

            http_response_code(409);

            echo json_encode([
                "success" => false,
                "message" => "Username already exists."
            ]);

            exit;
        }
    }

    // ========================================================
    // PASSWORD HASH
    // ========================================================

    $passwordHash = null;

    if ($loginAccess) {

        $passwordHash = password_hash(
            $password,
            PASSWORD_DEFAULT
        );

        if ($passwordHash === false) {

            http_response_code(500);

            echo json_encode([
                "success" => false,
                "message" => "Unable to secure the password."
            ]);

            exit;
        }
    }

    // ========================================================
    // DATE OF BIRTH
    // ========================================================

    $dob = null;

    if ($dateOfBirth !== '') {

        try {

            $dobDate = new DateTime($dateOfBirth);

            $dob = $dobDate->format('Y-m-d');
        } catch (Exception $e) {

            http_response_code(400);

            echo json_encode([
                "success" => false,
                "message" => "Invalid date of birth."
            ]);

            exit;
        }
    }

    // ========================================================
    // INSERT USER
    // ========================================================

    $sql = "
        INSERT INTO emp_users (
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
            username,
            password_hash,
            send_credentials
        )
        VALUES (
            :full_name,
            :employee_id,
            :email,
            :phone,
            :country_code,
            :department,
            :designation,
            :employee_type,
            :date_of_birth,
            :location,
            :role,
            :login_access,
            :username,
            :password_hash,
            :send_credentials
        )
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([

        ':full_name' =>
        $fullName,

        ':employee_id' =>
        $employeeId,

        ':email' =>
        $email !== ''
            ? $email
            : null,

        ':phone' =>
        $phone !== ''
            ? $phone
            : null,

        ':country_code' =>
        $countryCode !== ''
            ? $countryCode
            : null,

        ':department' =>
        $department !== ''
            ? $department
            : null,

        ':designation' =>
        $designation !== ''
            ? $designation
            : null,

        ':employee_type' =>
        $employeeType !== ''
            ? $employeeType
            : null,

        ':date_of_birth' =>
        $dob,

        ':location' =>
        $location !== ''
            ? $location
            : null,

        ':role' =>
        $role,

        ':login_access' =>
        $loginAccess
            ? 1
            : 0,

        ':username' =>
        $loginAccess
            ? $username
            : null,

        ':password_hash' =>
        $passwordHash,

        ':send_credentials' =>
        $loginAccess && $sendCredentials
            ? 1
            : 0
    ]);

    // ========================================================
    // CREATED USER ID
    // ========================================================

    $userId = $conn->lastInsertId();

    // ========================================================
    // SEND USER REGISTRATION EMAIL
    // ========================================================

    // IMPORTANT:
    // Initialize email status before using it in response.
    $emailSent = false;

    // Send email only when:
    // 1. Email is available
    // 2. send_credentials is enabled
    //
    // Login credentials will be included only when login access
    // is enabled.

    if ($email !== '' && $sendCredentials) {

        $emailSent = sendUserRegistrationEmail(
            $email,
            $fullName,
            $employeeId,
            $role,
            $loginAccess,
            $loginAccess ? $username : null,
            $loginAccess ? $password : null
        );
    }

    // ============================================================
    // SUCCESS RESPONSE
    // ============================================================

    http_response_code(201);

    echo json_encode([

        "success" => true,

        "message" =>
        $emailSent
            ? "User created successfully and registration email sent."
            : "User created successfully, but registration email could not be sent.",

        "created_by" => [

            "user_id" =>
            $currentUserId,

            "role" =>
            $currentUserRole
        ],

        "user_id" =>
        $userId,

        "email_sent" =>
        $emailSent,

        "user" => [

            "id" =>
            $userId,

            "full_name" =>
            $fullName,

            "employee_id" =>
            $employeeId,

            "email" =>
            $email,

            "phone" =>
            $phone,

            "country_code" =>
            $countryCode,

            "department" =>
            $department,

            "designation" =>
            $designation,

            "employee_type" =>
            $employeeType,

            "date_of_birth" =>
            $dob,

            "location" =>
            $location,

            "role" =>
            $role,

            "login_access" =>
            $loginAccess,

            "username" =>
            $loginAccess
                ? $username
                : null,

            "send_credentials" =>
            $loginAccess && $sendCredentials
        ]
    ]);
} catch (PDOException $e) {

    // ========================================================
    // DATABASE ERROR
    // ========================================================

    error_log(
        "Create User DB Error: "
            . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" =>
        "Unable to create user due to a database error."
    ]);
} catch (Exception $e) {

    // ========================================================
    // GENERAL ERROR
    // ========================================================

    error_log(
        "Create User Error: "
            . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" =>
        "An unexpected error occurred."
    ]);
}


// ============================================================
// SEND USER REGISTRATION EMAIL FUNCTION
// ============================================================

function sendUserRegistrationEmail(
    string $toEmail,
    string $fullName,
    string $employeeId,
    string $role,
    bool $loginAccess,
    ?string $username = null,
    ?string $password = null
): bool {

    try {

        // ========================================================
        // LOAD PHPMailer
        // ========================================================

        $phpMailerPath = __DIR__ . '/../../vendor/autoload.php';

        if (!file_exists($phpMailerPath)) {

            throw new Exception(
                'PHPMailer autoload file not found.'
            );
        }

        require_once $phpMailerPath;

        // ========================================================
        // MAIL CONFIG
        // ========================================================

        $mailConfig = require __DIR__ . '/../config/mail.php';

        $mail = new \PHPMailer\PHPMailer\PHPMailer(true);

        // ========================================================
        // SMTP
        // ========================================================

        $mail->isSMTP();

        $mail->Timeout = 10;

        $mail->Host =
            $mailConfig['host'];

        $mail->SMTPAuth =
            true;

        $mail->Username =
            $mailConfig['username'];

        $mail->Password =
            $mailConfig['password'];

        $mail->SMTPSecure =
            \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;

        $mail->Port =
            $mailConfig['port'];

        // ========================================================
        // CHARACTER SET
        // ========================================================

        $mail->CharSet = 'UTF-8';

        // ========================================================
        // FROM
        // ========================================================

        $mail->setFrom(
            $mailConfig['from_email'],
            $mailConfig['from_name']
        );

        // ========================================================
        // TO
        // ========================================================

        $mail->addAddress(
            $toEmail,
            $fullName
        );

        // ========================================================
        // EMAIL SUBJECT
        // ========================================================

        $mail->Subject =
            'Welcome to Asset Management System';

        // ========================================================
        // LOGIN INFORMATION
        // ========================================================

        $loginSection = '';

        if ($loginAccess) {

            $loginSection = '

                <h3 style="margin-top:25px;">
                    Login Information
                </h3>

                <table
                    cellpadding="8"
                    cellspacing="0"
                    border="0"
                    style="border-collapse:collapse;"
                >

                    <tr>

                        <td>
                            <strong>Username</strong>
                        </td>

                        <td>
                            ' .
                htmlspecialchars(
                    $username ?? '',
                    ENT_QUOTES,
                    'UTF-8'
                )
                . '
                        </td>

                    </tr>

                    <tr>

                        <td>
                            <strong>Password</strong>
                        </td>

                        <td>
                            ' .
                htmlspecialchars(
                    $password ?? '',
                    ENT_QUOTES,
                    'UTF-8'
                )
                . '
                        </td>

                    </tr>

                </table>

                <p style="margin-top:15px;">
                    Please change your password after your first login.
                </p>
            ';
        }

        // ========================================================
        // SAFE VALUES
        // ========================================================

        $safeFullName =
            htmlspecialchars(
                $fullName,
                ENT_QUOTES,
                'UTF-8'
            );

        $safeEmployeeId =
            htmlspecialchars(
                $employeeId,
                ENT_QUOTES,
                'UTF-8'
            );

        $safeRole =
            htmlspecialchars(
                $role,
                ENT_QUOTES,
                'UTF-8'
            );

        $safeEmail =
            htmlspecialchars(
                $toEmail,
                ENT_QUOTES,
                'UTF-8'
            );

        // ========================================================
        // HTML EMAIL
        // ========================================================

        $mail->isHTML(true);

        $mail->Body = '

<!DOCTYPE html>

<html>

<head>

    <meta charset="UTF-8">

    <title>
        Welcome
    </title>

</head>

<body
    style="
        margin:0;
        padding:0;
        background:#f4f6f8;
        font-family:Arial,Helvetica,sans-serif;
    "
>

    <div
        style="
            max-width:650px;
            margin:30px auto;
            background:#ffffff;
            border:1px solid #e1e5e9;
        "
    >

        <div
            style="
                padding:22px;
                background:#1f4e79;
                color:#ffffff;
            "
        >

            <h2 style="margin:0;">
                Asset Management System
            </h2>

        </div>

        <div
            style="
                padding:30px;
                color:#333333;
            "
        >

            <h3>
                Welcome ' . $safeFullName . ',
            </h3>

            <p>
                Your user account has been successfully
                created in the Asset Management System.
            </p>

            <h3>
                User Information
            </h3>

            <table
                cellpadding="8"
                cellspacing="0"
                border="0"
                style="
                    border-collapse:collapse;
                    width:100%;
                "
            >

                <tr>

                    <td
                        style="
                            border-bottom:1px solid #eeeeee;
                            width:180px;
                        "
                    >
                        <strong>
                            Employee ID
                        </strong>
                    </td>

                    <td
                        style="
                            border-bottom:1px solid #eeeeee;
                        "
                    >
                        ' . $safeEmployeeId . '
                    </td>

                </tr>

                <tr>

                    <td
                        style="
                            border-bottom:1px solid #eeeeee;
                        "
                    >
                        <strong>
                            Role
                        </strong>
                    </td>

                    <td
                        style="
                            border-bottom:1px solid #eeeeee;
                        "
                    >
                        ' . $safeRole . '
                    </td>

                </tr>

                <tr>

                    <td>
                        <strong>
                            Email
                        </strong>
                    </td>

                    <td>
                        ' . $safeEmail . '
                    </td>

                </tr>

            </table>

            ' . $loginSection . '

            <p style="margin-top:30px;">

                Regards,<br>

                <strong>
                    Asset Management System
                </strong>

            </p>

        </div>

    </div>

</body>

</html>
';

        // ========================================================
        // PLAIN TEXT FALLBACK
        // ========================================================

        $mail->AltBody =
            "Welcome {$fullName},\n\n" .
            "Your user account has been created.\n\n" .
            "Employee ID: {$employeeId}\n" .
            "Role: {$role}\n" .
            "Email: {$toEmail}\n";

        if ($loginAccess) {

            $mail->AltBody .=
                "\nLogin Information\n" .
                "Username: {$username}\n" .
                "Password: {$password}\n\n" .
                "Please change your password after your first login.\n";
        }

        // ========================================================
        // SEND
        // ========================================================

        $mail->send();

        return true;
    } catch (Throwable $e) {

        error_log(
            "Registration Email Error: "
                . $e->getMessage()
        );

        return false;
    }
}
