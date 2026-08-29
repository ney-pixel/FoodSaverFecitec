<?php
// Adiciona manualmente um item à lista de compras do usuário logado.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados         = corpoRequisicao();
$nomeAlimento  = trim($dados['nome_alimento'] ?? '');
$quantidadeStr = trim((string) ($dados['quantidade'] ?? ''));
$unidade       = trim($dados['unidade'] ?? $dados['unidade_medida'] ?? 'kg');

if (!$nomeAlimento || !$quantidadeStr) {
    responder(false, 'Preencha nome e quantidade.', [], 422);
}

$quantidade = normalizarDecimal($quantidadeStr);
if ($quantidade === null || $quantidade <= 0) {
    responder(false, 'Informe uma quantidade válida.', [], 422);
}

$stmt = $pdo->prepare(
    "INSERT INTO FS_lista_compras (usuario_id, nome_alimento, quantidade, unidade_medida, automatico) VALUES (?, ?, ?, ?, 0)"
);
$stmt->execute([$uid, $nomeAlimento, $quantidade, $unidade]);

responder(true, 'Item adicionado à lista!', ['id' => (int) $pdo->lastInsertId()]);
