<?php
// Conclui compras: move os itens marcados como comprados para o estoque.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados = corpoRequisicao();
$itens = $dados['itens'] ?? [];

if (!is_array($itens) || empty($itens)) {
    responder(false, 'Selecione ao menos um item comprado para concluir.', [], 422);
}

// Valida o formato de todos os itens antes de mexer no banco.
$itensValidados = [];
foreach ($itens as $it) {
    $id       = (int) ($it['id'] ?? 0);
    $validade = trim((string) ($it['validade'] ?? ''));
    if (!$id || !$validade) {
        responder(false, 'Informe a validade de todos os itens selecionados.', [], 422);
    }
    $data = DateTime::createFromFormat('Y-m-d', $validade);
    if (!$data || $data->format('Y-m-d') !== $validade) {
        responder(false, 'Data de validade inválida.', [], 422);
    }
    $itensValidados[] = ['id' => $id, 'validade' => $validade];
}

$pdo->beginTransaction();
try {
    $stmtBusca = $pdo->prepare(
        "SELECT nome_alimento, quantidade, unidade_medida FROM FS_lista_compras
         WHERE id = ? AND usuario_id = ? AND comprado = 1"
    );
    $stmtIns = $pdo->prepare(
        "INSERT INTO FS_alimentos (usuario_id, descricao, quantidade, unidade_medida, data_validade) VALUES (?, ?, ?, ?, ?)"
    );
    $stmtDel = $pdo->prepare("DELETE FROM FS_lista_compras WHERE id = ? AND usuario_id = ?");

    $concluidos = 0;
    foreach ($itensValidados as $it) {
        $stmtBusca->execute([$it['id'], $uid]);
        $item = $stmtBusca->fetch();
        if (!$item) {
            // não encontrado/comprado: ignora sem falhar o lote inteiro
            continue;
        }

        $stmtIns->execute([$uid, $item['nome_alimento'], $item['quantidade'], $item['unidade_medida'], $it['validade']]);
        $stmtDel->execute([$it['id'], $uid]);
        $concluidos++;
    }

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao concluir as compras.', [], 500);
}

if ($concluidos === 0) {
    responder(false, 'Nenhum dos itens selecionados pôde ser concluído.', [], 409);
}

responder(true, "$concluidos " . ($concluidos === 1 ? 'item adicionado' : 'itens adicionados') . ' ao estoque!', ['concluidos' => $concluidos]);
