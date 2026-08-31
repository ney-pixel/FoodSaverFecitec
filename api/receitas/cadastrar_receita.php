<?php
// Cadastra uma receita e vincula os alimentos do estoque selecionados.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados          = corpoRequisicao();
$titulo         = trim($dados['titulo'] ?? '');
$descricao      = trim($dados['descricao'] ?? '');
$modoPreparo    = trim($dados['modo_preparo'] ?? '');
$porcoes        = (int) ($dados['porcoes'] ?? 2);
$ingredientesId = $dados['ingredientes_sel'] ?? [];

if (!$titulo) {
    responder(false, 'Informe o título da receita.', [], 422);
}
if (!$modoPreparo) {
    responder(false, 'Descreva o modo de preparo da receita.', [], 422);
}
if ($porcoes < 1) {
    $porcoes = 1;
}
if (empty($ingredientesId) || !is_array($ingredientesId)) {
    responder(false, 'Selecione pelo menos um ingrediente do inventário.', [], 422);
}

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare(
        "INSERT INTO FS_receitas (usuario_id, titulo, descricao, porcoes, modo_preparo) VALUES (?, ?, ?, ?, ?)"
    );
    $stmt->execute([$uid, $titulo, $descricao, $porcoes, $modoPreparo]);
    $novaReceitaId = (int) $pdo->lastInsertId();

    $stmtIng = $pdo->prepare(
        "INSERT INTO FS_receita_alimentos (receita_id, alimento_id, quantidade, unidade_medida)
         SELECT ?, id, 1, unidade_medida FROM FS_alimentos WHERE id = ? AND usuario_id = ?"
    );
    $vinculados = 0;
    foreach ($ingredientesId as $alimentoId) {
        $stmtIng->execute([$novaReceitaId, (int) $alimentoId, $uid]);
        $vinculados += $stmtIng->rowCount();
    }

    if ($vinculados === 0) {
        $pdo->rollBack();
        responder(false, 'Os ingredientes selecionados não foram encontrados no seu inventário.', [], 422);
    }

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao salvar receita.', [], 500);
}

responder(true, 'Receita salva!', ['id' => $novaReceitaId]);
