<?php
// Edita uma receita existente e substitui suas relações de ingredientes
// em FS_receita_alimentos, preservando o vínculo com os alimentos do estoque.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST', 'PUT']);
$uid = exigirLogin();

$dados          = corpoRequisicao();
$id             = (int) ($dados['id'] ?? 0);
$titulo         = trim($dados['titulo'] ?? '');
$descricao      = trim($dados['descricao'] ?? '');
$modoPreparo    = trim($dados['modo_preparo'] ?? '');
$porcoes        = (int) ($dados['porcoes'] ?? 2);
$ingredientesId = $dados['ingredientes_sel'] ?? null;

if (!$id || !$titulo || !$modoPreparo) {
    responder(false, 'Preencha o título e o modo de preparo.', [], 422);
}

$chk = $pdo->prepare("SELECT id FROM FS_receitas WHERE id = ? AND usuario_id = ?");
$chk->execute([$id, $uid]);
if (!$chk->fetch()) {
    responder(false, 'Receita não encontrada.', [], 404);
}

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare(
        "UPDATE FS_receitas SET titulo=?, descricao=?, porcoes=?, modo_preparo=? WHERE id=? AND usuario_id=?"
    );
    $stmt->execute([$titulo, $descricao, $porcoes, $modoPreparo, $id, $uid]);

    // Se a lista de ingredientes foi enviada, substitui as relações existentes
    if (is_array($ingredientesId)) {
        $del = $pdo->prepare("DELETE FROM FS_receita_alimentos WHERE receita_id = ?");
        $del->execute([$id]);

        if (!empty($ingredientesId)) {
            $stmtIng = $pdo->prepare(
                "INSERT INTO FS_receita_alimentos (receita_id, alimento_id, quantidade, unidade_medida)
                 SELECT ?, id, 1, unidade_medida FROM FS_alimentos WHERE id = ? AND usuario_id = ?"
            );
            foreach ($ingredientesId as $alimentoId) {
                $stmtIng->execute([$id, (int) $alimentoId, $uid]);
            }
        }
    }

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao atualizar receita.', [], 500);
}

responder(true, 'Receita atualizada com sucesso!');
