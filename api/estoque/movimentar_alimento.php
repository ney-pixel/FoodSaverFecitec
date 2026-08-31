<?php
// Registra uma movimentação de estoque e ajusta a quantidade do alimento.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados      = corpoRequisicao();
$alimentoId = (int) ($dados['alimento_id'] ?? 0);
$tipo       = trim($dados['tipo'] ?? '');
$quantidade = normalizarDecimal($dados['quantidade'] ?? '') ?? 0.0;
$unidade    = trim($dados['unidade_medida'] ?? '');

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

if ($unidade === '') {
    $unidade = $alimento['unidade_medida'];
}

// Estoque sempre fica na unidade original do alimento
$quantidadeEstoque = converterQuantidade($quantidade, $unidade, $alimento['unidade_medida']);
if ($quantidadeEstoque === null) {
    responder(false, "Não é possível converter de \"{$unidade}\" para \"{$alimento['unidade_medida']}\".", [], 422);
}

if ($tipo === 'consumo' || $tipo === 'desperdicio') {
    if ($quantidadeEstoque > (float) $alimento['quantidade']) {
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
        $stmtUpd->execute([$quantidadeEstoque, $alimentoId]);
        $removido = false;
    } else {
        $stmtUpd = $pdo->prepare("UPDATE FS_alimentos SET quantidade = quantidade - ? WHERE id = ?");
        $stmtUpd->execute([$quantidadeEstoque, $alimentoId]);

        // Zerou o estoque: remove a linha (histórico continua intacto)
        $stmtCheck = $pdo->prepare("SELECT quantidade FROM FS_alimentos WHERE id = ?");
        $stmtCheck->execute([$alimentoId]);
        $quantidadeRestante = (float) $stmtCheck->fetchColumn();

        $removido = false;
        if ($quantidadeRestante <= 0.0001) {
            try {
                $stmtDel = $pdo->prepare("DELETE FROM FS_alimentos WHERE id = ?");
                $stmtDel->execute([$alimentoId]);
                $removido = true;
            } catch (PDOException $e) {
                // FK RESTRICT: alimento vinculado a uma receita, mantém o registro
            }
        }
    }

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao registrar movimentação.', [], 500);
}

responder(true, 'Movimentação registrada com sucesso.', ['alimento_removido' => $removido]);
