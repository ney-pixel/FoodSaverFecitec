<?php
// Cria um grupo de receitas da biblioteca para o usuário logado.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados = corpoRequisicao();
$nome  = trim($dados['nome'] ?? '');

if (!$nome) {
    responder(false, 'Informe o nome do grupo.', [], 422);
}

$stmt = $pdo->prepare("INSERT INTO FS_grupos_biblioteca (usuario_id, nome) VALUES (?, ?)");
$stmt->execute([$uid, $nome]);

responder(true, 'Grupo criado com sucesso!', ['id' => (int) $pdo->lastInsertId()]);
