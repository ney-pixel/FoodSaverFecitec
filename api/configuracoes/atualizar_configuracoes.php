<?php
// Atualiza as configurações do usuário logado: nome/e-mail (FS_usuarios),
// modo claro/escuro e alertas de validade (FS_configuracoes), e,
// opcionalmente, a senha (mesmas validações do antigo "alterar_senha").
//
// Cada bloco de dados é atualizado somente se enviado na requisição.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST', 'PUT']);
$uid = exigirLogin();

$dados = corpoRequisicao();
$resultado = [];

// ── PERFIL (nome/e-mail) ──────────────────────────────────
if (array_key_exists('username', $dados) || array_key_exists('email', $dados)) {
    $stmtAtual = $pdo->prepare("SELECT nome_usuario, email FROM FS_usuarios WHERE id = ?");
    $stmtAtual->execute([$uid]);
    $atual = $stmtAtual->fetch();

    $username = trim($dados['username'] ?? $atual['nome_usuario']);
    $email    = trim($dados['email'] ?? $atual['email']);

    if (strlen($username) < 3) {
        responder(false, 'Nome deve ter ao menos 3 caracteres.', [], 422);
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        responder(false, 'E-mail inválido.', [], 422);
    }

    $chk = $pdo->prepare("SELECT id FROM FS_usuarios WHERE email = ? AND id != ?");
    $chk->execute([$email, $uid]);
    if ($chk->fetch()) {
        responder(false, 'E-mail já está em uso por outra conta.', [], 409);
    }

    $upd = $pdo->prepare("UPDATE FS_usuarios SET nome_usuario = ?, email = ? WHERE id = ?");
    $upd->execute([$username, $email, $uid]);
    $_SESSION['usuario_nome'] = $username;
    $resultado['perfil'] = 'atualizado';
}

// ── SENHA ──────────────────────────────────────────────────
if (array_key_exists('senha_nova', $dados)) {
    $senhaAtual = trim($dados['senha_atual'] ?? '');
    $senhaNova  = trim($dados['senha_nova'] ?? '');
    $senhaConf  = trim($dados['senha_conf'] ?? $senhaNova);

    if (strlen($senhaNova) < 6) {
        responder(false, 'A nova senha deve ter ao menos 6 caracteres.', [], 422);
    }
    if ($senhaNova !== $senhaConf) {
        responder(false, 'As senhas não coincidem.', [], 422);
    }

    $stmt = $pdo->prepare("SELECT senha FROM FS_usuarios WHERE id = ?");
    $stmt->execute([$uid]);
    $row = $stmt->fetch();

    if (!password_verify($senhaAtual, $row['senha'])) {
        responder(false, 'Senha atual incorreta.', [], 401);
    }

    $hash = password_hash($senhaNova, PASSWORD_DEFAULT);
    $upd  = $pdo->prepare("UPDATE FS_usuarios SET senha = ? WHERE id = ?");
    $upd->execute([$hash, $uid]);
    $resultado['senha'] = 'atualizada';
}

// ── PREFERÊNCIAS (modo claro/escuro, alertas de validade) ───
if (array_key_exists('modo_tela', $dados) || array_key_exists('alertas_validade', $dados)) {
    $stmtCfg = $pdo->prepare("SELECT usuario_id, modo_tela, alertas_validade FROM FS_configuracoes WHERE usuario_id = ?");
    $stmtCfg->execute([$uid]);
    $atualCfg = $stmtCfg->fetch();

    $modoTela = $dados['modo_tela'] ?? ($atualCfg['modo_tela'] ?? 'claro');
    if (!in_array($modoTela, ['claro', 'escuro'], true)) {
        responder(false, 'Modo de tela inválido.', [], 422);
    }
    $alertas = array_key_exists('alertas_validade', $dados)
        ? (int) (bool) $dados['alertas_validade']
        : (int) ($atualCfg['alertas_validade'] ?? 1);

    if ($atualCfg) {
        $upd = $pdo->prepare("UPDATE FS_configuracoes SET modo_tela = ?, alertas_validade = ? WHERE usuario_id = ?");
        $upd->execute([$modoTela, $alertas, $uid]);
    } else {
        $ins = $pdo->prepare("INSERT INTO FS_configuracoes (usuario_id, modo_tela, alertas_validade) VALUES (?, ?, ?)");
        $ins->execute([$uid, $modoTela, $alertas]);
    }
    $resultado['preferencias'] = 'atualizadas';
}

if (empty($resultado)) {
    responder(false, 'Nenhum dado enviado para atualização.', [], 422);
}

responder(true, 'Configurações atualizadas com sucesso!', $resultado);
