<?php
// Cadastra um novo usuário em FS_usuarios, com as mesmas validações
// que existiam no cadastro.php original.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);

$dados    = corpoRequisicao();
$username = trim($dados['username'] ?? '');
$email    = trim($dados['email'] ?? '');
$senha    = trim($dados['senha'] ?? '');

$erros = [];
if (empty($username) || strlen($username) < 5) {
    $erros['username'] = 'O nome de usuário deve ter pelo menos 5 caracteres.';
}
if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $erros['email'] = 'Por favor, insira um e-mail válido.';
}
if (empty($senha) || strlen($senha) < 6) {
    $erros['senha'] = 'A senha deve ter pelo menos 6 caracteres.';
}
if (!empty($erros)) {
    responder(false, 'Dados inválidos.', ['erros' => $erros], 422);
}

$stmtCheck = $pdo->prepare("SELECT id FROM FS_usuarios WHERE email = ?");
$stmtCheck->execute([$email]);
if ($stmtCheck->fetch()) {
    responder(false, 'Este e-mail já está cadastrado.', ['erros' => ['email' => 'Este e-mail já está cadastrado.']], 409);
}

$senhaHash = password_hash($senha, PASSWORD_DEFAULT);

try {
    $stmt = $pdo->prepare("INSERT INTO FS_usuarios (nome_usuario, email, senha) VALUES (?, ?, ?)");
    $stmt->execute([$username, $email, $senhaHash]);
} catch (PDOException $e) {
    responder(false, 'Erro ao cadastrar usuário.', [], 500);
}

responder(true, 'Cadastro realizado com sucesso! Faça seu login.');
