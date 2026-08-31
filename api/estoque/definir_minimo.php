<?php
// Cria, edita ou remove uma quantidade mínima (por nome do alimento):
//   POST/PUT -> cria (sem "id") ou edita (com "id") um mínimo
//   DELETE   -> remove um mínimo pelo "id"

require_once __DIR__ . '/../helpers.php';

$uid    = exigirLogin();
$metodo = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'DELETE') {
    $dados = corpoRequisicao();
    $id    = (int) ($dados['id'] ?? $_GET['id'] ?? 0);
    if (!$id) {
        responder(false, 'Informe o mínimo a ser removido.', [], 422);
    }
    $stmt = $pdo->prepare("DELETE FROM FS_minimos_alimento WHERE id = ? AND usuario_id = ?");
    $stmt->execute([$id, $uid]);
    if ($stmt->rowCount() === 0) {
        responder(false, 'Mínimo não encontrado.', [], 404);
    }
    responder(true, 'Mínimo removido.');
}

exigirMetodo(['POST', 'PUT']);

$dados   = corpoRequisicao();
$id      = (int) ($dados['id'] ?? 0);
$nome    = trim($dados['nome'] ?? '');
$unidade = trim($dados['unidade'] ?? 'kg');
$qtdStr  = trim((string) ($dados['quantidade_minima'] ?? ''));

if (!$nome || !$qtdStr) {
    responder(false, 'Informe o alimento e a quantidade mínima.', [], 422);
}
$quantidade = normalizarDecimal($qtdStr);
if ($quantidade === null || $quantidade <= 0) {
    responder(false, 'Informe uma quantidade mínima válida.', [], 422);
}

if ($id) {
    $stmt = $pdo->prepare(
        "UPDATE FS_minimos_alimento SET nome_alimento = ?, unidade_medida = ?, quantidade_minima = ?
         WHERE id = ? AND usuario_id = ?"
    );
    $stmt->execute([$nome, $unidade, $quantidade, $id, $uid]);
    if ($stmt->rowCount() === 0) {
        $chk = $pdo->prepare("SELECT id FROM FS_minimos_alimento WHERE id = ? AND usuario_id = ?");
        $chk->execute([$id, $uid]);
        if (!$chk->fetch()) {
            responder(false, 'Mínimo não encontrado.', [], 404);
        }
    }
    responder(true, 'Mínimo atualizado!', ['id' => $id]);
}

// Evita duplicar: se já existir um mínimo pro alimento, atualiza em vez de criar
$existente = $pdo->prepare(
    "SELECT id FROM FS_minimos_alimento WHERE usuario_id = ? AND LOWER(TRIM(nome_alimento)) = LOWER(TRIM(?))"
);
$existente->execute([$uid, $nome]);
$row = $existente->fetch();

if ($row) {
    $up = $pdo->prepare("UPDATE FS_minimos_alimento SET unidade_medida = ?, quantidade_minima = ? WHERE id = ?");
    $up->execute([$unidade, $quantidade, $row['id']]);
    responder(true, 'Mínimo atualizado!', ['id' => (int) $row['id']]);
}

$ins = $pdo->prepare(
    "INSERT INTO FS_minimos_alimento (usuario_id, nome_alimento, unidade_medida, quantidade_minima) VALUES (?, ?, ?, ?)"
);
$ins->execute([$uid, $nome, $unidade, $quantidade]);
responder(true, 'Mínimo definido!', ['id' => (int) $pdo->lastInsertId()]);
