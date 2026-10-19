<?php
require_once '../db_connection.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->email) && !empty($data->password)) {
    $email = $data->email;
    $password = $data->password;

    $query = "SELECT id, email, password, role FROM users WHERE email = ? LIMIT 0,1";
    $stmt = $conn->prepare($query);
    $stmt->execute([$email]);

    if ($stmt->rowCount() > 0) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        $stored = $row['password'];
        $isValid = false;
        if (strpos($stored, '$2y$') === 0 || strpos($stored, '$2a$') === 0) {
            $isValid = password_verify($password, $stored);
        } else {
            // legacy plaintext fallback (migrate on success)
            $isValid = hash_equals($stored, $password);
        }
        if ($isValid) {
            http_response_code(200);
            echo json_encode(array(
                "message" => "Login successful",
                "user" => array(
                    "id" => $row['id'],
                    "email" => $row['email'],
                    "role" => $row['role']
                )
            ));
        } else {
            http_response_code(401);
            echo json_encode(array("message" => "Invalid credentials"));
        }
    } else {
        http_response_code(401);
        echo json_encode(array("message" => "User not found"));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data"));
}
?>