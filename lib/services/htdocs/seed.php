<?php
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
    echo "Menghubungkan ke database MySQL...\n";
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    die("Koneksi database gagal: " . $e->getMessage() . "\n");
}

// Buat tabel jika belum ada
$pdo->exec("CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    price DECIMAL(10, 2) NOT NULL,
    stock INT DEFAULT 0,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    brand VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

echo "Tabel 'products' siap.\nMengambil data dari DummyJSON API...\n";

$json = file_get_contents('https://dummyjson.com/products?limit=0');
if ($json === FALSE) {
    die("Gagal mengambil data dari DummyJSON API.\n");
}

$data = json_decode($json, true);
if (!isset($data['products'])) {
    die("Format data API tidak sesuai.\n");
}

$stmt = $pdo->prepare("INSERT INTO products (id, title, description, category, price, stock, rating, brand) 
    VALUES (:id, :title, :description, :category, :price, :stock, :rating, :brand)
    ON DUPLICATE KEY UPDATE 
    title = VALUES(title),
    description = VALUES(description),
    category = VALUES(category),
    price = VALUES(price),
    stock = VALUES(stock),
    rating = VALUES(rating),
    brand = VALUES(brand)");

$count = 0;
foreach ($data['products'] as $p) {
    $stmt->execute([
        ':id' => $p['id'],
        ':title' => $p['title'] ?? '',
        ':description' => $p['description'] ?? '',
        ':category' => $p['category'] ?? '',
        ':price' => $p['price'] ?? 0,
        ':stock' => $p['stock'] ?? 0,
        ':rating' => $p['rating'] ?? 0.0,
        ':brand' => $p['brand'] ?? ''
    ]);
    $count++;
}

echo "Berhasil melakukan seed sebanyak $count produk ke dalam database!\n";