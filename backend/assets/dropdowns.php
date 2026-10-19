<?php
require_once '../db_connection.php';

try {
    $tables = [
        'system' => 'asset_systems',
        'tag' => 'asset_tags',
        'type' => 'asset_types',
        'group_name' => 'asset_groups',
        'classification' => 'asset_classifications',
        'condition' => 'asset_conditions',
        'product_code' => 'product_codes',
        'model_type' => 'model_types',
        'manufacturer' => 'manufacturer_names',
        'supplier' => 'supplier_names',
        'cost_center' => 'cost_center_names'
    ];

    $response = [];

    foreach ($tables as $key => $table) {
        $stmt = $conn->query("SELECT name as label, name as value FROM $table ORDER BY name ASC");
        $response[$key] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Also fetch locations
    $stmt = $conn->query("SELECT id as value, CONCAT(site_name, ' - ', building_name, ' - ', room_name) as label FROM locations ORDER BY site_name ASC");
    $response['locations'] = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "data" => $response]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>