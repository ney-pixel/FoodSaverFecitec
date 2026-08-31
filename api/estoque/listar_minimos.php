<?php
// Lista os mínimos do usuário com a quantidade atual em estoque somada por nome.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

$stmt = $pdo->prepare(
    "SELECT id, nome_alimento, unidade_medida, quantidade_minima
     FROM FS_minimos_alimento WHERE usuario_id = ? ORDER BY nome_alimento ASC"
);
$stmt->execute([$uid]);
$minimos = $stmt->fetchAll();

$stmtLotes = $pdo->prepare(
    "SELECT quantidade, unidade_medida FROM FS_alimentos
     WHERE usuario_id = ? AND LOWER(TRIM(descricao)) = LOWER(TRIM(?))"
);

$resultado = [];
foreach ($minimos as $m) {
    $stmtLotes->execute([$uid, $m['nome_alimento']]);

    $atual = 0.0;
    foreach ($stmtLotes->fetchAll() as $lote) {
        // Lotes com unidade incompatível são ignorados na soma
        $convertido = converterQuantidade((float) $lote['quantidade'], $lote['unidade_medida'], $m['unidade_medida']);
        if ($convertido !== null) {
            $atual += $convertido;
        }
    }

    $resultado[] = [
        'id'                => (int) $m['id'],
        'nome_alimento'     => $m['nome_alimento'],
        'unidade_medida'    => $m['unidade_medida'],
        'quantidade_minima' => (float) $m['quantidade_minima'],
        'quantidade_atual'  => round($atual, 2),
        'abaixo_do_minimo'  => $atual < (float) $m['quantidade_minima'],
    ];
}

responder(true, '', ['minimos' => $resultado]);
