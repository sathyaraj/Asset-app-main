<?php

require_once __DIR__ . '/../db_connection.php';
require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../middleware/permission.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// ======================================================
// OPTIONS
// ======================================================

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ======================================================
// POST ONLY
// ======================================================

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

    // ==================================================
    // AUTHENTICATE JWT
    // ==================================================

    $decoded = authenticate();

    if (
        !$decoded ||
        !isset($decoded->user_id) ||
        empty($decoded->user_id)
    ) {
        http_response_code(401);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Unauthorized."
        ]);

        exit;
    }

    $userId = (int)$decoded->user_id;

    // ==================================================
    // CHECK CURRENT USER PERMISSION
    // ==================================================

    requirePermission(
        $conn,
        $userId,
        'role_management',
        'update'
    );

    // ==================================================
    // READ JSON INPUT
    // ==================================================

    $rawInput = file_get_contents('php://input');

    $input = json_decode(
        $rawInput,
        true
    );

    if (!is_array($input)) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Invalid JSON data."
        ]);

        exit;
    }

    // ==================================================
    // GET ROLE ID
    //
    // Flutter sends:
    // {
    //   "role_id": 2,
    //   "permissions": [...]
    // }
    //
    // Also supports old "role" field.
    // ==================================================

    $roleId = (int)(
        $input['role_id']
        ?? $input['role']
        ?? 0
    );

    $permissions = $input['permissions'] ?? [];

    if ($roleId <= 0) {
        http_response_code(422);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "role_id is required."
        ]);

        exit;
    }

    if (!is_array($permissions)) {
        http_response_code(422);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "permissions must be an array."
        ]);

        exit;
    }

    // ==================================================
    // GET ROLE
    // ==================================================

    $roleStmt = $conn->prepare("
        SELECT
            id,
            name,
            value,
            is_active
        FROM roles
        WHERE id = ?
        LIMIT 1
    ");

    $roleStmt->execute([
        $roleId
    ]);

    $role = $roleStmt->fetch(PDO::FETCH_ASSOC);

    if (!$role) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Role not found."
        ]);

        exit;
    }

    // ==================================================
    // CHECK ROLE ACTIVE
    // ==================================================

    if ((int)$role['is_active'] !== 1) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" =>
                "Cannot update permissions for an inactive role."
        ]);

        exit;
    }

    // ==================================================
    // IMPORTANT
    //
    // role_page_permissions.role stores:
    //
    // admin
    // cafm_manager
    // supervisor
    // facilities_executive
    // technician
    //
    // NOT role ID.
    // ==================================================

    $roleValue = trim(
        (string)$role['value']
    );

    if ($roleValue === '') {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Role value is not configured."
        ]);

        exit;
    }

    // ==================================================
    // START TRANSACTION
    // ==================================================

    $conn->beginTransaction();

    // ==================================================
    // PAGE CHECK
    // ==================================================

    $pageCheck = $conn->prepare("
        SELECT
            id
        FROM pages
        WHERE id = ?
          AND is_active = 1
        LIMIT 1
    ");

    // ==================================================
    // INSERT / UPDATE PERMISSION
    // ==================================================

    $permissionStmt = $conn->prepare("
        INSERT INTO role_page_permissions
        (
            role,
            page_id,
            can_view,
            can_create,
            can_update,
            can_delete
        )
        VALUES
        (
            :role,
            :page_id,
            :can_view,
            :can_create,
            :can_update,
            :can_delete
        )

        ON DUPLICATE KEY UPDATE

            can_view = VALUES(can_view),
            can_create = VALUES(can_create),
            can_update = VALUES(can_update),
            can_delete = VALUES(can_delete)
    ");

    $savedCount = 0;

    // ==================================================
    // SAVE EACH PAGE PERMISSION
    // ==================================================

    foreach ($permissions as $permission) {

        if (!is_array($permission)) {
            continue;
        }

        $pageId = (int)(
            $permission['page_id'] ?? 0
        );

        if ($pageId <= 0) {
            continue;
        }

        // ----------------------------------------------
        // Verify page exists and is active
        // ----------------------------------------------

        $pageCheck->execute([
            $pageId
        ]);

        if (!$pageCheck->fetch()) {
            continue;
        }

        // ----------------------------------------------
        // Permission values
        // ----------------------------------------------

        $canView = !empty(
            $permission['can_view']
        ) ? 1 : 0;

        $canCreate = !empty(
            $permission['can_create']
        ) ? 1 : 0;

        $canUpdate = !empty(
            $permission['can_update']
        ) ? 1 : 0;

        $canDelete = !empty(
            $permission['can_delete']
        ) ? 1 : 0;

        // ----------------------------------------------
        // Create / Update / Delete requires View
        // ----------------------------------------------

        if ($canView === 0) {
            $canCreate = 0;
            $canUpdate = 0;
            $canDelete = 0;
        }

        // ----------------------------------------------
        // SAVE
        // ----------------------------------------------

        $permissionStmt->execute([
            ':role' => $roleValue,
            ':page_id' => $pageId,
            ':can_view' => $canView,
            ':can_create' => $canCreate,
            ':can_update' => $canUpdate,
            ':can_delete' => $canDelete
        ]);

        $savedCount++;
    }

    // ==================================================
    // COMMIT
    // ==================================================

    $conn->commit();

    // ==================================================
    // SUCCESS
    // ==================================================

    http_response_code(200);

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Permissions saved successfully.",
        "role_id" => $roleId,
        "role" => $roleValue,
        "saved_count" => $savedCount
    ]);

    exit;

} catch (PDOException $e) {

    // ==================================================
    // ROLLBACK
    // ==================================================

    if (
        isset($conn) &&
        $conn instanceof PDO &&
        $conn->inTransaction()
    ) {
        $conn->rollBack();
    }

    error_log(
        "Permissions Save Database Error: "
        . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Failed to save permissions."
    ]);

    exit;

} catch (Exception $e) {

    // ==================================================
    // ROLLBACK
    // ==================================================

    if (
        isset($conn) &&
        $conn instanceof PDO &&
        $conn->inTransaction()
    ) {
        $conn->rollBack();
    }

    error_log(
        "Permissions Save Error: "
        . $e->getMessage()
    );

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "An unexpected error occurred."
    ]);

    exit;
}