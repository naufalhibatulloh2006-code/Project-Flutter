<?php
declare(strict_types=1);

class ProductController {
    // Pemetaan nama field dari client (camelCase / snake_case) ke kolom database.
    private const FIELD_MAP = [
        'title'                  => 'title',
        'description'            => 'description',
        'category'               => 'category',
        'price'                  => 'price',
        'discountPercentage'     => 'discount_percentage',
        'discount_percentage'    => 'discount_percentage',
        'rating'                 => 'rating',
        'stock'                  => 'stock',
        'tags'                   => 'tags',
        'brand'                  => 'brand',
        'sku'                    => 'sku',
        'weight'                 => 'weight',
        'dimensions'             => 'dimensions',
        'warrantyInformation'    => 'warranty_information',
        'warranty_information'   => 'warranty_information',
        'shippingInformation'    => 'shipping_information',
        'shipping_information'   => 'shipping_information',
        'availabilityStatus'     => 'availability_status',
        'availability_status'    => 'availability_status',
        'reviews'                => 'reviews',
        'returnPolicy'           => 'return_policy',
        'return_policy'          => 'return_policy',
        'minimumOrderQuantity'   => 'minimum_order_quantity',
        'minimum_order_quantity' => 'minimum_order_quantity',
        'meta'                   => 'product_meta',
        'product_meta'           => 'product_meta',
        'thumbnail'              => 'thumbnail',
        'images'                 => 'images',
    ];

    private const JSON_COLUMNS   = ['tags', 'dimensions', 'reviews', 'product_meta', 'images'];
    private const FLOAT_COLUMNS  = ['price', 'discount_percentage', 'rating'];
    private const INT_COLUMNS    = ['stock', 'weight', 'minimum_order_quantity'];

    // Kolom yang boleh dipakai untuk pengurutan (sortBy).
    private const SORT_MAP = [
        'id'                 => 'id',
        'title'              => 'title',
        'price'              => 'price',
        'rating'             => 'rating',
        'stock'              => 'stock',
        'brand'              => 'brand',
        'category'           => 'category',
        'discountPercentage' => 'discount_percentage',
        'discount_percentage'=> 'discount_percentage',
    ];

    public function __construct(private PDO $pdo) {}

    public function initialiseDatabase(): void {
        // Membuat tabel secara otomatis dengan struktur lengkap
        $this->pdo->exec("CREATE TABLE IF NOT EXISTS products (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT NOT NULL,
            category VARCHAR(100) NOT NULL,
            price DECIMAL(12, 2) NOT NULL,
            discount_percentage DECIMAL(8, 2) DEFAULT 0,
            rating DECIMAL(4, 2) DEFAULT 0,
            stock INT DEFAULT 0,
            tags JSON DEFAULT NULL,
            brand VARCHAR(255) DEFAULT NULL,
            sku VARCHAR(100) DEFAULT NULL,
            weight INT DEFAULT 0,
            dimensions JSON DEFAULT NULL,
            warranty_information VARCHAR(255) DEFAULT NULL,
            shipping_information VARCHAR(255) DEFAULT NULL,
            availability_status VARCHAR(100) DEFAULT NULL,
            reviews JSON DEFAULT NULL,
            return_policy VARCHAR(255) DEFAULT NULL,
            minimum_order_quantity INT DEFAULT 1,
            product_meta JSON DEFAULT NULL,
            thumbnail TEXT DEFAULT NULL,
            images JSON DEFAULT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )");

        // Auto-import data dari DummyJSON jika tabel masih kosong
        $stmt = $this->pdo->query("SELECT COUNT(*) FROM products");
        if ($stmt->fetchColumn() == 0) {
            $url = "https://dummyjson.com/products?limit=0";
            $response = @file_get_contents($url);
            if ($response !== false) {
                $data = json_decode($response, true);
                if (!empty($data['products'])) {
                    $sql = "INSERT INTO products (
                        title, description, category, price, discount_percentage, rating, stock,
                        tags, brand, sku, weight, dimensions, warranty_information, shipping_information,
                        availability_status, reviews, return_policy, minimum_order_quantity, product_meta, thumbnail, images
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

                    $stmtInsert = $this->pdo->prepare($sql);
                    foreach ($data['products'] as $p) {
                        $stmtInsert->execute([
                            $p['title'] ?? '',
                            $p['description'] ?? '',
                            $p['category'] ?? '',
                            $p['price'] ?? 0,
                            $p['discountPercentage'] ?? 0,
                            $p['rating'] ?? 0,
                            $p['stock'] ?? 0,
                            isset($p['tags']) ? json_encode($p['tags']) : null,
                            $p['brand'] ?? 'Unknown',
                            $p['sku'] ?? '',
                            $p['weight'] ?? 0,
                            isset($p['dimensions']) ? json_encode($p['dimensions']) : null,
                            $p['warrantyInformation'] ?? '',
                            $p['shippingInformation'] ?? '',
                            $p['availabilityStatus'] ?? '',
                            isset($p['reviews']) ? json_encode($p['reviews']) : null,
                            $p['returnPolicy'] ?? '',
                            $p['minimumOrderQuantity'] ?? 1,
                            isset($p['meta']) ? json_encode($p['meta']) : null,
                            $p['thumbnail'] ?? '',
                            isset($p['images']) ? json_encode($p['images']) : null
                        ]);
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------
    // Helper
    // ---------------------------------------------------------------

    private function respondError(int $code, string $message): void {
        http_response_code($code);
        echo json_encode(["error" => $message]);
    }

    /** Baca body JSON; kembalikan array kosong jika tidak valid. */
    private function readInput(): array {
        $raw = file_get_contents('php://input');
        if ($raw === false || trim($raw) === '') {
            return [];
        }
        $data = json_decode($raw, true);
        return is_array($data) ? $data : [];
    }

    /**
     * Ubah input client menjadi [kolom => nilai] yang aman untuk disimpan.
     * Hanya kolom yang ada di FIELD_MAP yang diterima.
     */
    private function buildColumns(array $data): array {
        $cols = [];
        foreach ($data as $key => $val) {
            if (!is_string($key) || !isset(self::FIELD_MAP[$key])) {
                continue;
            }
            $col = self::FIELD_MAP[$key];

            if (in_array($col, self::JSON_COLUMNS, true)) {
                if ($val === null) {
                    $cols[$col] = null;
                } elseif (is_string($val)) {
                    json_decode($val);
                    $cols[$col] = (json_last_error() === JSON_ERROR_NONE)
                        ? $val
                        : json_encode($val);
                } else {
                    $cols[$col] = json_encode($val);
                }
            } elseif (in_array($col, self::FLOAT_COLUMNS, true)) {
                $cols[$col] = is_numeric($val) ? (float)$val : 0.0;
            } elseif (in_array($col, self::INT_COLUMNS, true)) {
                $cols[$col] = is_numeric($val) ? (int)$val : 0;
            } else {
                $cols[$col] = is_scalar($val) ? (string)$val : '';
            }
        }
        return $cols;
    }

    private function exists(int $id): bool {
        $stmt = $this->pdo->prepare("SELECT 1 FROM products WHERE id = ?");
        $stmt->execute([$id]);
        return (bool)$stmt->fetchColumn();
    }

    // ---------------------------------------------------------------
    // READ
    // ---------------------------------------------------------------

    public function getAll(): void {
        // limit = 0 berarti ambil semua produk
        $limit = isset($_GET['limit']) ? max(0, (int)$_GET['limit']) : 0;
        $skip  = isset($_GET['skip'])  ? max(0, (int)$_GET['skip'])  : 0;

        $sortBy = $_GET['sortBy'] ?? 'id';
        $sortCol = self::SORT_MAP[$sortBy] ?? 'id';
        $order = strtolower((string)($_GET['order'] ?? 'asc')) === 'desc' ? 'DESC' : 'ASC';

        $sql = "SELECT * FROM products ORDER BY `$sortCol` $order";
        if ($limit > 0) {
            $sql .= " LIMIT :limit OFFSET :skip";
        }

        $stmt = $this->pdo->prepare($sql);
        if ($limit > 0) {
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->bindValue(':skip', $skip, PDO::PARAM_INT);
        }
        $stmt->execute();
        $products = $stmt->fetchAll();

        $total = $this->pdo->query("SELECT COUNT(*) FROM products")->fetchColumn();

        echo json_encode([
            "products" => $products,
            "total"    => (int)$total,
            "skip"     => $skip,
            "limit"    => $limit
        ]);
    }

    public function getCategories(): void {
        $stmt = $this->pdo->query("SELECT DISTINCT category FROM products WHERE category IS NOT NULL");
        $categories = [];
        while ($row = $stmt->fetch()) {
            $categories[] = [
                "name" => ucfirst($row['category']),
                "slug" => $row['category'],
                "url"  => "https://dummyjson.com/products/category/" . $row['category']
            ];
        }
        echo json_encode($categories);
    }

    public function getByCategory(string $category): void {
        $stmt = $this->pdo->prepare("SELECT * FROM products WHERE category = ?");
        $stmt->execute([$category]);
        $products = $stmt->fetchAll();
        echo json_encode([
            "products" => $products,
            "total"    => count($products)
        ]);
    }

    public function search(string $query): void {
        $stmt = $this->pdo->prepare("SELECT * FROM products WHERE title LIKE ? OR description LIKE ?");
        $stmt->execute(["%$query%", "%$query%"]);
        $products = $stmt->fetchAll();
        echo json_encode([
            "products" => $products,
            "total"    => count($products)
        ]);
    }

    public function show(int $id): void {
        $stmt = $this->pdo->prepare("SELECT * FROM products WHERE id = ?");
        $stmt->execute([$id]);
        $product = $stmt->fetch();
        if ($product) {
            echo json_encode($product);
        } else {
            $this->respondError(404, "Produk tidak ditemukan");
        }
    }

    // ---------------------------------------------------------------
    // CREATE
    // ---------------------------------------------------------------

    public function store(): void {
        $data = $this->readInput();
        $cols = $this->buildColumns($data);

        // Validasi field wajib
        $title    = trim((string)($cols['title'] ?? ''));
        $category = trim((string)($cols['category'] ?? ''));
        if ($title === '') {
            $this->respondError(422, "Judul produk wajib diisi");
            return;
        }
        if ($category === '') {
            $this->respondError(422, "Kategori produk wajib diisi");
            return;
        }
        if (!isset($cols['price']) || $cols['price'] < 0) {
            $this->respondError(422, "Harga produk tidak valid");
            return;
        }

        $cols['title']       = $title;
        $cols['category']    = $category;
        $cols['description'] = $cols['description'] ?? '';

        $names        = array_keys($cols);
        $columnList   = '`' . implode('`, `', $names) . '`';
        $placeholders = implode(', ', array_fill(0, count($names), '?'));

        $stmt = $this->pdo->prepare("INSERT INTO products ($columnList) VALUES ($placeholders)");
        $stmt->execute(array_values($cols));

        $id = (int)$this->pdo->lastInsertId();
        http_response_code(201);
        $this->show($id);
    }

    // ---------------------------------------------------------------
    // UPDATE (PUT / PATCH)
    // ---------------------------------------------------------------

    public function update(int $id): void {
        if (!$this->exists($id)) {
            $this->respondError(404, "Produk tidak ditemukan");
            return;
        }

        $data = $this->readInput();
        $cols = $this->buildColumns($data);

        // Kolom NOT NULL tidak boleh dikosongkan
        foreach (['title', 'category'] as $required) {
            if (array_key_exists($required, $cols) && trim((string)$cols[$required]) === '') {
                $this->respondError(422, "Field '$required' tidak boleh kosong");
                return;
            }
        }
        if (array_key_exists('description', $cols) && $cols['description'] === null) {
            $cols['description'] = '';
        }

        if (!empty($cols)) {
            $sets = [];
            foreach (array_keys($cols) as $name) {
                $sets[] = "`$name` = ?";
            }
            $values   = array_values($cols);
            $values[] = $id;

            $stmt = $this->pdo->prepare("UPDATE products SET " . implode(', ', $sets) . " WHERE id = ?");
            $stmt->execute($values);
        }

        $this->show($id);
    }

    // ---------------------------------------------------------------
    // DELETE
    // ---------------------------------------------------------------

    public function destroy(int $id): void {
        $stmt = $this->pdo->prepare("SELECT * FROM products WHERE id = ?");
        $stmt->execute([$id]);
        $product = $stmt->fetch();
        if ($product) {
            $del = $this->pdo->prepare("DELETE FROM products WHERE id = ?");
            $del->execute([$id]);
            echo json_encode($product);
        } else {
            $this->respondError(404, "Produk tidak ditemukan");
        }
    }
}