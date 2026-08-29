<?php
// Registra uma movimentação de estoque (entrada, consumo ou desperdício)
// em FS_movimentacoes e ajusta a quantidade do alimento em FS_alimentos.
// Essa movimentação é o que alimenta os relatórios de impacto.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

// Converte uma quantidade entre unidades compatíveis (só massa, por ora).
// Unidades iguais sempre "convertem" 1:1. Retorna null se não for possível.
function converterQuantidade(float $qtd, string $de, string $para): ?float
{
    if ($de === $para) {
        return $qtd;
    }
    $fatoresParaGramas = ['kg' => 1000, 'g' => 1];
    if (isset($fatoresParaGramas[$de]) && isset($fatoresParaGramas[$para])) {
        return $qtd * $fatoresParaGramas[$de] / $fatoresParaGramas[$para];
    }
    return null;
}

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

// A movimentação é registrada na unidade escolhida pelo usuário, mas o
// estoque em FS_alimentos sempre fica na unidade original do alimento.
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
    } else {
        $stmtUpd = $pdo->prepare("UPDATE FS_alimentos SET quantidade = quantidade - ? WHERE id = ?");
    }
    $stmtUpd->execute([$quantidadeEstoque, $alimentoId]);

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao registrar movimentação.', [], 500);
}

responder(true, 'Movimentação registrada com sucesso.');
