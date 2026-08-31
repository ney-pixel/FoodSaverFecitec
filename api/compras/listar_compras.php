<?php
// Lista a lista de compras e sincroniza itens automáticos por mínimo.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

// 1) Sincroniza itens automáticos com base na quantidade mínima
$stmtMinimos = $pdo->prepare(
    "SELECT nome_alimento, unidade_medida, quantidade_minima FROM FS_minimos_alimento WHERE usuario_id = ?"
);
$stmtMinimos->execute([$uid]);
$minimos = $stmtMinimos->fetchAll();

$stmtLotes = $pdo->prepare(
    "SELECT quantidade, unidade_medida FROM FS_alimentos
     WHERE usuario_id = ? AND LOWER(TRIM(descricao)) = LOWER(TRIM(?))"
);
$stmtBuscaAuto = $pdo->prepare(
    "SELECT id, quantidade FROM FS_lista_compras WHERE usuario_id = ? AND nome_alimento = ? AND automatico = 1 AND comprado = 0"
);
$stmtInsereAuto = $pdo->prepare(
    "INSERT INTO FS_lista_compras (usuario_id, nome_alimento, quantidade, unidade_medida, automatico) VALUES (?, ?, ?, ?, 1)"
);
$stmtAtualizaAuto = $pdo->prepare(
    "UPDATE FS_lista_compras SET quantidade = ? WHERE id = ?"
);
$stmtRemoveAuto = $pdo->prepare(
    "DELETE FROM FS_lista_compras WHERE id = ?"
);

$nomesAindaAbaixoDoMinimo = [];

foreach ($minimos as $m) {
    // Soma todos os lotes desse alimento (mesmo nome)
    $stmtLotes->execute([$uid, $m['nome_alimento']]);
    $atual = 0.0;
    foreach ($stmtLotes->fetchAll() as $lote) {
        $convertido = converterQuantidade((float) $lote['quantidade'], $lote['unidade_medida'], $m['unidade_medida']);
        if ($convertido !== null) {
            $atual += $convertido;
        }
    }

    $abaixoDoMinimo = $atual < (float) $m['quantidade_minima'];

    $stmtBuscaAuto->execute([$uid, $m['nome_alimento']]);
    $existente = $stmtBuscaAuto->fetch();

    if ($abaixoDoMinimo && !$existente) {
        $deficit = round((float) $m['quantidade_minima'] - $atual, 2);
        $stmtInsereAuto->execute([$uid, $m['nome_alimento'], $deficit, $m['unidade_medida']]);
    } elseif ($abaixoDoMinimo && $existente) {
        // Mantém a quantidade necessária em dia
        $deficit = round((float) $m['quantidade_minima'] - $atual, 2);
        if ($deficit !== round((float) $existente['quantidade'], 2)) {
            $stmtAtualizaAuto->execute([$deficit, $existente['id']]);
        }
    } elseif (!$abaixoDoMinimo && $existente) {
        // Voltou a ficar acima do mínimo: remove o item automático ainda não comprado
        $stmtRemoveAuto->execute([$existente['id']]);
    }

    if ($abaixoDoMinimo) {
        $nomesAindaAbaixoDoMinimo[] = $m['nome_alimento'];
    }
}

// 1.1) Limpa itens automáticos órfãos (alimento excluído/mínimo removido)
$stmtAutosPendentes = $pdo->prepare(
    "SELECT id, nome_alimento FROM FS_lista_compras WHERE usuario_id = ? AND automatico = 1 AND comprado = 0"
);
$stmtAutosPendentes->execute([$uid]);
foreach ($stmtAutosPendentes->fetchAll() as $auto) {
    if (!in_array($auto['nome_alimento'], $nomesAindaAbaixoDoMinimo, true)) {
        $stmtRemoveAuto->execute([$auto['id']]);
    }
}

// 2) Retorna a lista completa
$stmt = $pdo->prepare(
    "SELECT id, nome_alimento, quantidade, unidade_medida, automatico, comprado, data_adicao
     FROM FS_lista_compras WHERE usuario_id = ? ORDER BY comprado ASC, data_adicao DESC"
);
$stmt->execute([$uid]);

$lista = [];
foreach ($stmt->fetchAll() as $row) {
    $lista[] = [
        'id'            => (int) $row['id'],
        'nome_alimento' => $row['nome_alimento'],
        'quantidade'    => (float) $row['quantidade'],
        'unidade_medida'=> $row['unidade_medida'],
        'automatico'    => (bool) $row['automatico'],
        'comprado'      => (bool) $row['comprado'],
        'data_adicao'   => $row['data_adicao'],
    ];
}

responder(true, '', ['lista_compras' => $lista]);
