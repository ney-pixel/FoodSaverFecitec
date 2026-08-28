<?php
// Exclui um grupo de alimentos do usuário logado.
// FS_grupo_alimentos (as associações do grupo com os alimentos) cai em
// cascata (ON DELETE CASCADE) — os alimentos em si não são afetados.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST', 'DELETE']);
$uid = exigirLogin();

$dados   = corpoRequisicao();
$grupoId = (int) ($dados['grupo_id'] ?? $dados['id'] ?? $_GET['id'] ?? 0);

if (!$grupoId) {
    responder(false, 'Informe o grupo a ser excluído.', [], 422);
}

$stmt = $pdo->prepare("DELETE FROM FS_grupos_alimentos WHERE id = ? AND usuario_id = ?");
$stmt->execute([$grupoId, $uid]);

if ($stmt->rowCount() === 0) {
    responder(false, 'Grupo não encontrado.', [], 404);
}

responder(true, 'Grupo excluído com sucesso.');
