<?php
// Cadastra um novo usuário em FS_usuarios, com validações reforçadas
// (formato de usuário/e-mail, força mínima de senha, senha != usuário/e-mail).

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);

$dados    = corpoRequisicao();
$username = trim($dados['username'] ?? '');
$email    = strtolower(trim($dados['email'] ?? ''));
$senha    = (string) ($dados['senha'] ?? ''); // senha não é "trimada": espaços podem ser intencionais

$erros = [];

if ($username === '') {
    $erros['username'] = 'Informe um nome de usuário.';
} elseif (mb_strlen($username) < 5 || mb_strlen($username) > 30) {
    $erros['username'] = 'O nome de usuário deve ter entre 5 e 30 caracteres.';
} elseif (!preg_match('/^[\p{L}\p{N}_.-]+$/u', $username)) {
    $erros['username'] = 'Use apenas letras, números, ponto, hífen ou underscore (sem espaços).';
}

if ($email === '') {
    $erros['email'] = 'Informe seu e-mail.';
} elseif (strlen($email) > 150 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $erros['email'] = 'Por favor, insira um e-mail válido.';
}

if ($senha === '') {
    $erros['senha'] = 'Crie uma senha.';
} elseif (mb_strlen($senha) < 6 || mb_strlen($senha) > 72) {
    $erros['senha'] = 'A senha deve ter entre 6 e 72 caracteres.';
} elseif (!preg_match('/^(?=.*[A-Za-zÀ-ÿ])(?=.*\d).+$/u', $senha)) {
    $erros['senha'] = 'A senha deve conter letras e números.';
} elseif (strcasecmp($senha, $username) === 0 || strcasecmp($senha, $email) === 0) {
    $erros['senha'] = 'A senha não pode ser igual ao usuário ou ao e-mail.';
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
