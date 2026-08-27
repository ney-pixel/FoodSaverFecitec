<?php
// Exclui um alimento do estoque do usuário logado.
// FS_alimentos_minimos e FS_grupo_alimentos caem em cascata (ON DELETE CASCADE).
// FS_movimentacoes e FS_receita_alimentos usam ON DELETE RESTRICT: se o
// alimento tiver histórico de movimentação ou estiver vinculado a alguma
// receita, a exclusão é bloqueada pelo próprio banco.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST', 'DELETE']);
$uid = exigirLogin();

$dados = corpoRequisicao();
$id    = (int) ($dados['id'] ?? $_GET['id'] ?? 0);

if (!$id) {
    responder(false, 'Informe o alimento a ser excluído.', [], 422);
}

try {
    $stmt = $pdo->prepare("DELETE FROM FS_alimentos WHERE id = ? AND usuario_id = ?");
    $stmt->execute([$id, $uid]);
} catch (PDOException $e) {
    // Violação de FK (RESTRICT) em FS_movimentacoes ou FS_receita_alimentos
    responder(false, 'Não é possível excluir: este alimento está vinculado a receitas ou movimentações.', [], 409);
}

if ($stmt->rowCount() === 0) {
    responder(false, 'Alimento não encontrado.', [], 404);
}

responder(true, 'Alimento excluído com sucesso.');
