<?php
//excluir receita

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST', 'DELETE']);
$uid = exigirLogin();

$dados = corpoRequisicao();
$id    = (int) ($dados['id'] ?? $_GET['id'] ?? 0);

if (!$id) {
    responder(false, 'Informe a receita a ser excluída.', [], 422);
}

$stmt = $pdo->prepare("DELETE FROM FS_receitas WHERE id = ? AND usuario_id = ?");
$stmt->execute([$id, $uid]);

if ($stmt->rowCount() === 0) {
    responder(false, 'Receita não encontrada.', [], 404);
}

responder(true, 'Receita excluída com sucesso.');
