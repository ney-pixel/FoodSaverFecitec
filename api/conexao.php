<?php
// Conexão com o banco de dados via PDO (prepared statements nativos).
// Mesmas credenciais/host/banco usados anteriormente com mysqli.

$host   = "143.106.241.4";
$usuario = "cl204211";
$senha   = "cl#08112008";
$banco   = "cl204211";

try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$banco};charset=utf8",
        $usuario,
        $senha,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'sucesso'  => false,
        'mensagem' => 'Erro na conexão com o banco de dados.',
    ]);
    exit;
}
