<?php
header("Content-Type: text/html; charset=UTF-8");

// Konfigurasi Koneksi Database (mengikuti environment Docker Anda)
$host = 'mysql';
$db   = 'app';
$user = 'app';
$pass = '';
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
    die("Koneksi database gagal: " . $e->getMessage());
}

// Mengambil seluruh data produk dari API DummyJSON (limit=0 mengambil semua data)
$url = "https://dummyjson.com/products?limit=0"; 
$response = file_get_contents($url);

if ($response === FALSE) {
    die("Gagal mengambil data dari API DummyJSON.");
}

$data = json_decode($response, true);
$products = $data['products'] ?? [];

if (empty($products)) {
    die("Tidak ada produk yang ditemukan dari API.");
}

// Menyiapkan query Prepared Statement
$stmt = $pdo->prepare("INSERT INTO products (title, description, category, price, rating, stock, brand) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE title=VALUES(title), description=VALUES(description), price=VALUES(price)");

$insertedCount = 0;
foreach ($products as $product) {
    $stmt->execute([
        $product['title'] ?? '',
        $product['description'] ?? '',
        $product['category'] ?? '',
        $product['price'] ?? 0,
        $product['rating'] ?? 0,
        $product['stock'] ?? 0,
        $product['brand'] ?? 'Unknown'
    ]);
    $insertedCount++;
}

echo "<h2>Berhasil!</h2>";
echo "<p>Seluruh <strong>$insertedCount</strong> produk berhasil diimpor ke dalam database MySQL dan siap ditampilkan di phpMyAdmin.</p>";