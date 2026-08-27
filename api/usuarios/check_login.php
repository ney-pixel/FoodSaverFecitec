<?php
// Verifica se existe uma sessão de usuário válida.
// Usado pelo front-end para proteger páginas como perfil.html.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);

if (!isset($_SESSION['usuario_id'])) {
    responder(false, 'Nenhuma sessão ativa.', ['logado' => false], 401);
}

$uid = (int) $_SESSION['usuario_id'];

$stmt = $pdo->prepare("SELECT id, nome_usuario AS username, email, plano, ativo FROM FS_usuarios WHERE id = ?");
$stmt->execute([$uid]);
$usuario = $stmt->fetch();

if (!$usuario) {
    session_destroy();
    responder(false, 'Sessão inválida.', ['logado' => false], 401);
}

responder(true, 'Sessão válida.', [
    'logado'  => true,
    'usuario' => [
        'id'       => (int) $usuario['id'],
        'username' => $usuario['username'],
        'email'    => $usuario['email'],
        'plano'    => $usuario['plano'],
        'ativo'    => (bool) $usuario['ativo'],
    ],
]);
