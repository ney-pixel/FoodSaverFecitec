<?php
// Gerencia os grupos de alimentos do usuário logado:
//   GET    -> lista os grupos com seus alimentos
//   POST   -> adiciona um alimento a um grupo
//   DELETE -> remove um alimento de um grupo

require_once __DIR__ . '/../helpers.php';

$uid = exigirLogin();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmtGrupos = $pdo->prepare("SELECT id, nome FROM FS_grupos_alimentos WHERE usuario_id = ? ORDER BY nome");
    $stmtGrupos->execute([$uid]);
    $grupos = $stmtGrupos->fetchAll();

    $stmtItens = $pdo->prepare(
        "SELECT ga.grupo_id, a.id, a.descricao AS nome, a.quantidade, a.unidade_medida AS unidade
         FROM FS_grupo_alimentos ga
         JOIN FS_alimentos a ON a.id = ga.alimento_id
         WHERE ga.grupo_id = ?"
    );

    $resultado = [];
    foreach ($grupos as $grupo) {
        $stmtItens->execute([$grupo['id']]);
        $itens = [];
        foreach ($stmtItens->fetchAll() as $it) {
            $itens[] = [
                'id'         => (int) $it['id'],
                'nome'       => $it['nome'],
                'quantidade' => (float) $it['quantidade'],
                'unidade'    => $it['unidade'],
            ];
        }
        $resultado[] = [
            'id'        => (int) $grupo['id'],
            'nome'      => $grupo['nome'],
            'alimentos' => $itens,
        ];
    }

    responder(true, '', ['grupos' => $resultado]);
}

$dados     = corpoRequisicao();
$grupoId   = (int) ($dados['grupo_id'] ?? 0);
$alimentoId = (int) ($dados['alimento_id'] ?? 0);

if (!$grupoId || !$alimentoId) {
    responder(false, 'Informe o grupo e o alimento.', [], 422);
}

$chkGrupo = $pdo->prepare("SELECT id FROM FS_grupos_alimentos WHERE id = ? AND usuario_id = ?");
$chkGrupo->execute([$grupoId, $uid]);
if (!$chkGrupo->fetch()) {
    responder(false, 'Grupo não encontrado.', [], 404);
}

$chkAlimento = $pdo->prepare("SELECT id FROM FS_alimentos WHERE id = ? AND usuario_id = ?");
$chkAlimento->execute([$alimentoId, $uid]);
if (!$chkAlimento->fetch()) {
    responder(false, 'Alimento não encontrado.', [], 404);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $stmt = $pdo->prepare("INSERT IGNORE INTO FS_grupo_alimentos (grupo_id, alimento_id) VALUES (?, ?)");
    $stmt->execute([$grupoId, $alimentoId]);
    responder(true, 'Alimento adicionado ao grupo.');
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $stmt = $pdo->prepare("DELETE FROM FS_grupo_alimentos WHERE grupo_id = ? AND alimento_id = ?");
    $stmt->execute([$grupoId, $alimentoId]);
    responder(true, 'Alimento removido do grupo.');
}

responder(false, 'Método HTTP não permitido.', [], 405);
