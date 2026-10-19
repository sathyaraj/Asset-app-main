<?php

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;
use Firebase\JWT\BeforeValidException;


// ----------------------------------------
// Get Authorization Header
// ----------------------------------------
function getAuthorizationHeader()
{
    $headers = [];

    if (function_exists('getallheaders')) {
        $headers = getallheaders();
    }

    // Apache / XAMPP
    if (isset($headers['Authorization'])) {
        return trim($headers['Authorization']);
    }

    // Sometimes header name can be lowercase
    if (isset($headers['authorization'])) {
        return trim($headers['authorization']);
    }

    // Fallback
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        return trim($_SERVER['HTTP_AUTHORIZATION']);
    }

    return null;
}


// ----------------------------------------
// Verify JWT
// ----------------------------------------
function authenticate()
{
    $authHeader = getAuthorizationHeader();


    // ----------------------------------------
    // No Authorization Header
    // ----------------------------------------
    if (!$authHeader) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Authorization token is required."
        ]);

        exit;
    }


    // ----------------------------------------
    // Expected format:
    // Authorization: Bearer YOUR_TOKEN
    // ----------------------------------------
    if (!preg_match('/Bearer\s+(.+)/i', $authHeader, $matches)) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Invalid Authorization header format."
        ]);

        exit;
    }


    // ----------------------------------------
    // Get Token
    // ----------------------------------------
    $token = trim($matches[1]);


    // ----------------------------------------
    // Empty Token
    // ----------------------------------------
    if (empty($token)) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Token is empty."
        ]);

        exit;
    }


    // ----------------------------------------
    // Decode and Verify JWT
    // ----------------------------------------
    try {

        $decoded = JWT::decode(
            $token,
            new Key(JWT_SECRET, 'HS256')
        );

        return $decoded;

    } catch (ExpiredException $e) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Token has expired."
        ]);

        exit;

    } catch (SignatureInvalidException $e) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Invalid token signature."
        ]);

        exit;

    } catch (BeforeValidException $e) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Token is not valid yet."
        ]);

        exit;

    } catch (Exception $e) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Invalid or malformed token."
        ]);

        exit;
    }
}
