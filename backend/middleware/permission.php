<?php

// ============================================================
// REQUIRED FILES
// ============================================================

require_once __DIR__ . '/../db_connection.php';


// ============================================================
// CHECK PERMISSION
// ============================================================

function requirePermission(
    $conn,
    int $userId,
    string $pageKey,
    string $action
): void {

    // ========================================================
    // ALLOWED ACTIONS
    // ========================================================

    $allowedActions = [
        'view',
        'create',
        'update',
        'delete'
    ];

    if (!in_array($action, $allowedActions, true)) {

        http_response_code(400);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Invalid permission action."
        ]);

        exit;
    }


    // ========================================================
    // PERMISSION COLUMN
    // ========================================================

    $permissionColumn = 'can_' . $action;


    // ========================================================
    // GET USER ROLE
    //
    // Actual user table:
    // emp_users
    //
    // Actual role column:
    // role
    // ========================================================

    try {

        $stmt = $conn->prepare("
            SELECT
                id,
                role
            FROM emp_users
            WHERE id = ?
            LIMIT 1
        ");

        $stmt->execute([
            $userId
        ]);

        $user = $stmt->fetch(PDO::FETCH_ASSOC);

    } catch (PDOException $e) {

        error_log(
            "Permission User Role Error: " .
            $e->getMessage()
        );

        http_response_code(500);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Unable to verify user permission."
        ]);

        exit;
    }


    // ========================================================
    // USER NOT FOUND
    // ========================================================

    if (!$user) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "User not found."
        ]);

        exit;
    }


    // ========================================================
    // USER ROLE
    //
    // Example:
    // cafm_manager
    // ========================================================

    $roleValue = trim(
        (string)($user['role'] ?? '')
    );


    if ($roleValue === '') {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "User role is not configured."
        ]);

        exit;
    }


    // ========================================================
    // CHECK ROLE PAGE PERMISSION
    //
    // IMPORTANT:
    //
    // role_page_permissions uses:
    //     role
    //
    // NOT:
    //     role_id
    //
    // ========================================================

    try {

        $query = "
            SELECT
                rpp.$permissionColumn AS allowed

            FROM role_page_permissions rpp

            INNER JOIN roles r
                ON r.value = rpp.role

            INNER JOIN pages p
                ON p.id = rpp.page_id

            WHERE r.value = ?
              AND p.page_key = ?
              AND r.is_active = 1
              AND p.is_active = 1

            LIMIT 1
        ";


        $stmt = $conn->prepare($query);

        $stmt->execute([
            $roleValue,
            $pageKey
        ]);


        $permission = $stmt->fetch(
            PDO::FETCH_ASSOC
        );


    } catch (PDOException $e) {

        error_log(
            "Permission Check DB Error: " .
            $e->getMessage()
        );

        http_response_code(500);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" => "Unable to verify permission."
        ]);

        exit;
    }


    // ========================================================
    // PERMISSION DENIED
    // ========================================================

    if (
        !$permission ||
        (int)$permission['allowed'] !== 1
    ) {

        http_response_code(403);

        echo json_encode([
            "success" => false,
            "status" => "error",
            "message" =>
                "You do not have permission to perform this action."
        ]);

        exit;
    }


    // ========================================================
    // PERMISSION ALLOWED
    // ========================================================

    return;
}
