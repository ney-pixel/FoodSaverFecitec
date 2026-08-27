<?php
// Lista os itens da lista de compras do usuário logado.
//
// Também mantém a lógica de quantidade mínima:
//   FS_alimentos -> FS_alimentos_minimos -> quantidade atual < quantidade mínima?
//   -> gera (ou remove, se não for mais o caso) um item automático em FS_lista_compras.
// Essa verificação fica só aqui, sem endpoint próprio, conforme pedido.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

// 1) Sincroniza itens automáticos com base na quantidade mínima
$stmtMinimos = $pdo->prepare(
    "SELECT a.id, a.descricao, a.quantidade, a.unidade_medida, m.quantidade_minima
     FROM FS_alimentos a
     JOIN FS_alimentos_minimos m ON m.alimento_id = a.id
     WHERE a.usuario_id = ?"
);
$stmtMinimos->execute([$uid]);
$alimentosComMinimo = $stmtMinimos->fetchAll();

$stmtBuscaAuto = $pdo->prepare(
    "SELECT id FROM FS_lista_compras WHERE usuario_id = ? AND nome_alimento = ? AND automatico = 1 AND comprado = 0"
);
$stmtInsereAuto = $pdo->prepare(
    "INSERT INTO FS_lista_compras (usuario_id, nome_alimento, quantidade, unidade_medida, automatico) VALUES (?, ?, ?, ?, 1)"
);
$stmtRemoveAuto = $pdo->prepare(
    "DELETE FROM FS_lista_compras WHERE id = ?"
);

foreach ($alimentosComMinimo as $a) {
    $abaixoDoMinimo = (float) $a['quantidade'] < (float) $a['quantidade_minima'];

    $stmtBuscaAuto->execute([$uid, $a['descricao']]);
    $existente = $stmtBuscaAuto->fetch();

    if ($abaixoDoMinimo && !$existente) {
        $deficit = (float) $a['quantidade_minima'] - (float) $a['quantidade'];
        $stmtInsereAuto->execute([$uid, $a['descricao'], $deficit, $a['unidade_medida']]);
    } elseif (!$abaixoDoMinimo && $existente) {
        // Voltou a ficar acima do mínimo: remove o item automático ainda não comprado
        $stmtRemoveAuto->execute([$existente['id']]);
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
