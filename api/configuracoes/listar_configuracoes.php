<?php
// Busca as configurações atuais do usuário logado.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

$stmt = $pdo->prepare("SELECT nome_usuario AS username, email, plano FROM FS_usuarios WHERE id = ?");
$stmt->execute([$uid]);
$usuario = $stmt->fetch();

if (!$usuario) {
    responder(false, 'Usuário não encontrado.', [], 404);
}

$stmtCfg = $pdo->prepare("SELECT modo_tela, alertas_validade FROM FS_configuracoes WHERE usuario_id = ?");
$stmtCfg->execute([$uid]);
$config = $stmtCfg->fetch();

// Sem linha ainda: cria com os padrões da tabela
if (!$config) {
    $ins = $pdo->prepare("INSERT INTO FS_configuracoes (usuario_id) VALUES (?)");
    $ins->execute([$uid]);
    $config = ['modo_tela' => 'claro', 'alertas_validade' => 1];
}

responder(true, '', [
    'configuracoes' => [
        'username'         => $usuario['username'],
        'email'            => $usuario['email'],
        'plano'            => $usuario['plano'],
        'modo_tela'        => $config['modo_tela'],
        'alertas_validade' => (bool) $config['alertas_validade'],
    ],
]);
