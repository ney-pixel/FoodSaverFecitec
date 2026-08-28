<?php
// Registra uma movimentação de estoque (entrada, consumo ou desperdício)
// em FS_movimentacoes e ajusta a quantidade do alimento em FS_alimentos.
// Essa movimentação é o que alimenta os relatórios de impacto.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados      = corpoRequisicao();
$alimentoId = (int) ($dados['alimento_id'] ?? 0);
$tipo       = trim($dados['tipo'] ?? '');
$quantidade = (float) ($dados['quantidade'] ?? 0);

$tiposValidos = ['entrada', 'consumo', 'desperdicio'];
if (!$alimentoId || !in_array($tipo, $tiposValidos, true) || $quantidade <= 0) {
    responder(false, 'Dados inválidos para movimentação.', [], 422);
}

$stmtAlimento = $pdo->prepare("SELECT id, descricao, quantidade, unidade_medida FROM FS_alimentos WHERE id = ? AND usuario_id = ?");
$stmtAlimento->execute([$alimentoId, $uid]);
$alimento = $stmtAlimento->fetch();

if (!$alimento) {
    responder(false, 'Alimento não encontrado.', [], 404);
}

$unidade = $dados['unidade_medida'] ?? $alimento['unidade_medida'];

if ($tipo === 'consumo' || $tipo === 'desperdicio') {
    if ($quantidade > (float) $alimento['quantidade']) {
        responder(false, 'Quantidade informada é maior que o estoque disponível.', [], 422);
    }
}

$pdo->beginTransaction();
try {
    $stmtMov = $pdo->prepare(
        "INSERT INTO FS_movimentacoes (usuario_id, alimento_id, descricao_alimento, tipo, quantidade, unidade_medida) VALUES (?, ?, ?, ?, ?, ?)"
    );
    $stmtMov->execute([$uid, $alimentoId, $alimento['descricao'], $tipo, $quantidade, $unidade]);

    if ($tipo === 'entrada') {
        $stmtUpd = $pdo->prepare("UPDATE FS_alimentos SET quantidade = quantidade + ? WHERE id = ?");
    } else {
        $stmtUpd = $pdo->prepare("UPDATE FS_alimentos SET quantidade = quantidade - ? WHERE id = ?");
    }
    $stmtUpd->execute([$quantidade, $alimentoId]);

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao registrar movimentação.', [], 500);
}

responder(true, 'Movimentação registrada com sucesso.');
