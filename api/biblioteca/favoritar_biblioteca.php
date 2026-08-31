<?php
// Alterna favorito de uma receita da biblioteca para o usuário logado.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados = corpoRequisicao();
$id    = (int) ($dados['id'] ?? 0);

if (!$id) {
    responder(false, 'Informe a receita.', [], 422);
}

$chk = $pdo->prepare("SELECT id FROM FS_biblioteca_receitas WHERE id = ?");
$chk->execute([$id]);
if (!$chk->fetch()) {
    responder(false, 'Receita não encontrada.', [], 404);
}

$stmt = $pdo->prepare("SELECT 1 FROM FS_biblioteca_favoritos WHERE usuario_id = ? AND receita_id = ?");
$stmt->execute([$uid, $id]);
$jaFavoritada = (bool) $stmt->fetch();

if ($jaFavoritada) {
    $pdo->prepare("DELETE FROM FS_biblioteca_favoritos WHERE usuario_id = ? AND receita_id = ?")->execute([$uid, $id]);
} else {
    $pdo->prepare("INSERT INTO FS_biblioteca_favoritos (usuario_id, receita_id) VALUES (?, ?)")->execute([$uid, $id]);
}

responder(true, $jaFavoritada ? 'Receita removida dos favoritos.' : 'Receita adicionada aos favoritos.', [
    'favorito' => !$jaFavoritada,
]);
