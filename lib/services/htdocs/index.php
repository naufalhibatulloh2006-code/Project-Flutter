<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = 'mysql';
$db   = 'app';
$user = 'app';
$pass = 'app_secret';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed: " . $e->getMessage()]);
    exit();
}

// Panggil Controller & Jalankan Inisialisasi Otomatis (Buat Tabel + Seeding)
require_once(__DIR__ . '/controller/ProductController.php');
$controller = new ProductController($pdo);
$controller->initialiseDatabase();

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri = trim($uri, '/');
$segments = explode('/', $uri);
$method = $_SERVER['REQUEST_METHOD'];

if (!isset($segments[0]) || $segments[0] !== 'products') {
    http_response_code(404);
    echo json_encode(["error" => "Endpoint tidak ditemukan"]);
    exit();
}

$action = $segments[1] ?? null;
$param = $segments[2] ?? null;

// Routing Endpoint
if ($action === 'category-list' && $method === 'GET') {
    $stmt = $pdo->query(
        "SELECT DISTINCT category FROM products
         WHERE category IS NOT NULL AND category <> ''
         ORDER BY category"
    );
    echo json_encode($stmt->fetchAll(PDO::FETCH_COLUMN));
    exit();
}
if ($action === 'categories' && $method === 'GET') {
    $controller->getCategories();
    exit();
}

if ($action === 'category' && isset($param) && $method === 'GET') {
    $controller->getByCategory(urldecode($param));
    exit();
}

if ($action === 'search' && $method === 'GET') {
    $q = $_GET['q'] ?? '';
    $controller->search($q);
    exit();
}

if ($action === 'add' && $method === 'POST') {
    $controller->store();
    exit();
}

if (is_numeric($action)) {
    $id = (int)$action;
    if ($method === 'GET') {
        $controller->show($id);
        exit();
    }
    if ($method === 'PUT' || $method === 'PATCH') {
        $controller->update($id);
        exit();
    }
    if ($method === 'DELETE') {
        $controller->destroy($id);
        exit();
    }
}

if ($action === null && $method === 'GET') {
    $controller->getAll();
    exit();
}

http_response_code(404);
echo json_encode(["error" => "Endpoint tidak valid"]);