<?php
// Autentica o usuário e cria a sessão. Reativa a conta automaticamente
// se ela estava desativada (ativo = 0), igual ao comportamento anterior.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);

$dados = corpoRequisicao();
$email = trim($dados['email'] ?? '');
$senha = trim($dados['senha'] ?? '');

$erros = [];
if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $erros['email'] = 'Por favor, insira um e-mail válido.';
}
if (empty($senha)) {
    $erros['senha'] = 'A senha é obrigatória.';
}
if (!empty($erros)) {
    responder(false, 'Dados inválidos.', ['erros' => $erros], 422);
}

$stmt = $pdo->prepare("SELECT id, nome_usuario AS username, senha, ativo FROM FS_usuarios WHERE email = ?");
$stmt->execute([$email]);
$usuario = $stmt->fetch();

if (!$usuario) {
    responder(false, 'E-mail não encontrado.', ['erros' => ['email' => 'E-mail não encontrado.']], 401);
}

if (empty($usuario['senha']) || !password_verify($senha, $usuario['senha'])) {
    responder(false, 'Senha incorreta.', ['erros' => ['senha' => 'Senha incorreta.']], 401);
}

// Se a conta estava desativada, reativa automaticamente ao logar
if ((int) ($usuario['ativo'] ?? 1) === 0) {
    $reativa = $pdo->prepare("UPDATE FS_usuarios SET ativo = 1 WHERE id = ?");
    $reativa->execute([$usuario['id']]);
}

$_SESSION['usuario_id']   = (int) $usuario['id'];
$_SESSION['usuario_nome'] = $usuario['username'];

responder(true, 'Login realizado com sucesso.', [
    'usuario' => [
        'id'       => (int) $usuario['id'],
        'username' => $usuario['username'],
    ],
]);
