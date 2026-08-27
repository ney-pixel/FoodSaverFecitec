<?php
// Cadastra uma receita e vincula os alimentos do estoque selecionados
// como ingredientes (FS_receita_alimentos), preservando a relação:
// receita -> FS_receita_alimentos -> alimentos do estoque.

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
    responder(false, 'Descreva o modo de preparo.', [], 422);
}

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare(
        "INSERT INTO FS_receitas (usuario_id, titulo, descricao, porcoes, modo_preparo) VALUES (?, ?, ?, ?, ?)"
    );
    $stmt->execute([$uid, $titulo, $descricao, $porcoes, $modoPreparo]);
    $novaReceitaId = (int) $pdo->lastInsertId();

    if (!empty($ingredientesId) && is_array($ingredientesId)) {
        $stmtIng = $pdo->prepare(
            "INSERT INTO FS_receita_alimentos (receita_id, alimento_id, quantidade, unidade_medida)
             SELECT ?, id, 1, unidade_medida FROM FS_alimentos WHERE id = ? AND usuario_id = ?"
        );
        foreach ($ingredientesId as $alimentoId) {
            $stmtIng->execute([$novaReceitaId, (int) $alimentoId, $uid]);
        }
    }

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao salvar receita.', [], 500);
}

responder(true, 'Receita salva!', ['id' => $novaReceitaId]);
