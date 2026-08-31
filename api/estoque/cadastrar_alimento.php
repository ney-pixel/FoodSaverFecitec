<?php
// Cadastra um novo alimento no estoque do usuário logado.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados         = corpoRequisicao();
$nome          = trim($dados['nome'] ?? '');
$quantidadeStr = trim((string) ($dados['quantidade'] ?? ''));
$unidade       = trim($dados['unidade'] ?? 'kg');
$validade      = trim($dados['validade'] ?? '');

if (!$nome || !$quantidadeStr || !$validade) {
    responder(false, 'Preencha todos os campos.', [], 422);
}

$quantidade = normalizarDecimal($quantidadeStr);
if ($quantidade === null || $quantidade <= 0) {
    responder(false, 'Informe uma quantidade válida.', [], 422);
}

$pdo->beginTransaction();
try {
    // Mesmo item = nome, unidade e validade iguais: soma em vez de criar linha
    $stmtExistente = $pdo->prepare(
        "SELECT id FROM FS_alimentos
         WHERE usuario_id = ? AND LOWER(TRIM(descricao)) = LOWER(TRIM(?))
           AND unidade_medida = ? AND data_validade = ?"
    );
    $stmtExistente->execute([$uid, $nome, $unidade, $validade]);
    $existente = $stmtExistente->fetch();

    $mesclado = false;

    if ($existente) {
        $stmtUpd = $pdo->prepare("UPDATE FS_alimentos SET quantidade = quantidade + ? WHERE id = ?");
        $stmtUpd->execute([$quantidade, $existente['id']]);

        $novoId   = (int) $existente['id'];
        $mesclado = true;
    } else {
        $stmt = $pdo->prepare(
            "INSERT INTO FS_alimentos (usuario_id, descricao, quantidade, unidade_medida, data_validade) VALUES (?, ?, ?, ?, ?)"
        );
        $stmt->execute([$uid, $nome, $quantidade, $unidade, $validade]);
        $novoId = (int) $pdo->lastInsertId();
    }

    // Marca como comprado o item pendente correspondente na lista de compras
    $stmtLista = $pdo->prepare(
        "UPDATE FS_lista_compras SET comprado = 1
         WHERE usuario_id = ? AND comprado = 0 AND LOWER(TRIM(nome_alimento)) = LOWER(TRIM(?))"
    );
    $stmtLista->execute([$uid, $nome]);

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao cadastrar alimento.', [], 500);
}

responder(true, $mesclado ? 'Quantidade somada ao item já existente no estoque!' : 'Item adicionado!', ['id' => $novoId, 'mesclado' => $mesclado]);
