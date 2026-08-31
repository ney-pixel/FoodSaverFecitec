<?php
// Edita um alimento existente do usuário logado.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST', 'PUT']);
$uid = exigirLogin();

$dados         = corpoRequisicao();
$id            = (int) ($dados['id'] ?? 0);
$nome          = trim($dados['nome'] ?? '');
$quantidadeStr = trim((string) ($dados['quantidade'] ?? ''));
$unidade       = trim($dados['unidade'] ?? 'kg');
$validade      = trim($dados['validade'] ?? '');

if (!$id || !$nome || !$quantidadeStr || !$validade) {
    responder(false, 'Preencha todos os campos.', [], 422);
}

$quantidade = normalizarDecimal($quantidadeStr);
if ($quantidade === null || $quantidade <= 0) {
    responder(false, 'Informe uma quantidade válida.', [], 422);
}

$stmt = $pdo->prepare(
    "UPDATE FS_alimentos SET descricao=?, quantidade=?, unidade_medida=?, data_validade=? WHERE id=? AND usuario_id=?"
);
$stmt->execute([$nome, $quantidade, $unidade, $validade, $id, $uid]);

if ($stmt->rowCount() === 0) {
    // Pode não ter mudado nenhum valor; confirma se o item existe e pertence ao usuário
    $chk = $pdo->prepare("SELECT id FROM FS_alimentos WHERE id = ? AND usuario_id = ?");
    $chk->execute([$id, $uid]);
    if (!$chk->fetch()) {
        responder(false, 'Alimento não encontrado.', [], 404);
    }
}

responder(true, 'Item atualizado!');
