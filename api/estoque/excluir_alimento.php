<?php
// Exclui um alimento do estoque do usuário logado.
// FS_alimentos_minimos e FS_grupo_alimentos caem em cascata (ON DELETE CASCADE).
// FS_movimentacoes NÃO bloqueia mais a exclusão: ao excluir o alimento, o
// alimento_id das movimentações antigas vira NULL automaticamente
// (ON DELETE SET NULL), mas o nome do alimento continua salvo em
// descricao_alimento — os relatórios de histórico continuam intactos.
// FS_receita_alimentos ainda usa ON DELETE RESTRICT: se o alimento estiver
// vinculado a alguma receita (do site), a exclusão continua bloqueada.

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
    // Violação de FK (RESTRICT) em FS_receita_alimentos
    responder(false, 'Não é possível excluir: este alimento está vinculado a uma receita.', [], 409);
}

if ($stmt->rowCount() === 0) {
    responder(false, 'Alimento não encontrado.', [], 404);
}

responder(true, 'Alimento excluído com sucesso.');
