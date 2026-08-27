<?php
// Cadastra um novo alimento no estoque do usuário logado.
// Aceita opcionalmente "quantidade_minima" para alimentar a lista de
// compras automática (FS_alimentos_minimos), usada por listar_compras.php.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados      = corpoRequisicao();
$nome       = trim($dados['nome'] ?? '');
$quantidade = trim((string) ($dados['quantidade'] ?? ''));
$unidade    = trim($dados['unidade'] ?? 'kg');
$validade   = trim($dados['validade'] ?? '');
$qtdMinima  = $dados['quantidade_minima'] ?? null;

if (!$nome || !$quantidade || !$validade) {
    responder(false, 'Preencha todos os campos.', [], 422);
}

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare(
        "INSERT INTO FS_alimentos (usuario_id, descricao, quantidade, unidade_medida, data_validade) VALUES (?, ?, ?, ?, ?)"
    );
    $stmt->execute([$uid, $nome, $quantidade, $unidade, $validade]);
    $novoId = (int) $pdo->lastInsertId();

    if ($qtdMinima !== null && $qtdMinima !== '') {
        $stmtMin = $pdo->prepare("INSERT INTO FS_alimentos_minimos (alimento_id, quantidade_minima) VALUES (?, ?)");
        $stmtMin->execute([$novoId, (float) $qtdMinima]);
    }

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao cadastrar alimento.', [], 500);
}

responder(true, 'Item adicionado!', ['id' => $novoId]);
