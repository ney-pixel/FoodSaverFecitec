<?php
// Desativa a conta do usuário logado (reativada automaticamente no próximo login).

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$stmt = $pdo->prepare("UPDATE FS_usuarios SET ativo = 0 WHERE id = ?");
$stmt->execute([$uid]);

$_SESSION = [];
session_destroy();

responder(true, 'Conta desativada. Faça login novamente a qualquer momento para reativá-la.');
