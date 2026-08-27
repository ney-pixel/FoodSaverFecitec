<?php
// Adiciona ou remove uma receita dos favoritos do usuário (coluna
// FS_receitas.favorito). Alterna o valor atual (toggle).

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados = corpoRequisicao();
$id    = (int) ($dados['id'] ?? 0);

if (!$id) {
    responder(false, 'Informe a receita.', [], 422);
}

$stmt = $pdo->prepare("SELECT favorito FROM FS_receitas WHERE id = ? AND usuario_id = ?");
$stmt->execute([$id, $uid]);
$receita = $stmt->fetch();

if (!$receita) {
    responder(false, 'Receita não encontrada.', [], 404);
}

$novoValor = $receita['favorito'] ? 0 : 1;

$upd = $pdo->prepare("UPDATE FS_receitas SET favorito = ? WHERE id = ? AND usuario_id = ?");
$upd->execute([$novoValor, $id, $uid]);

responder(true, $novoValor ? 'Receita adicionada aos favoritos.' : 'Receita removida dos favoritos.', [
    'favorito' => (bool) $novoValor,
]);
