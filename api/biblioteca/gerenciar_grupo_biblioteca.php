<?php
// Gerencia os grupos de receitas da biblioteca do usuário logado:
//   GET    -> lista os grupos com suas receitas
//   POST   -> adiciona uma receita da biblioteca a um grupo
//   DELETE -> remove uma receita de um grupo

require_once __DIR__ . '/../helpers.php';

$uid = exigirLogin();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmtGrupos = $pdo->prepare("SELECT id, nome FROM FS_grupos_biblioteca WHERE usuario_id = ? ORDER BY nome");
    $stmtGrupos->execute([$uid]);
    $grupos = $stmtGrupos->fetchAll();

    $stmtItens = $pdo->prepare(
        "SELECT gb.grupo_id, b.id, b.titulo, b.porcoes
         FROM FS_grupo_biblioteca gb
         JOIN FS_biblioteca_receitas b ON b.id = gb.receita_id
         WHERE gb.grupo_id = ?"
    );

    $resultado = [];
    foreach ($grupos as $grupo) {
        $stmtItens->execute([$grupo['id']]);
        $itens = [];
        foreach ($stmtItens->fetchAll() as $it) {
            $itens[] = [
                'id'      => (int) $it['id'],
                'titulo'  => $it['titulo'],
                'porcoes' => (int) $it['porcoes'],
            ];
        }
        $resultado[] = [
            'id'       => (int) $grupo['id'],
            'nome'     => $grupo['nome'],
            'receitas' => $itens,
        ];
    }

    responder(true, '', ['grupos' => $resultado]);
}

$dados     = corpoRequisicao();
$grupoId   = (int) ($dados['grupo_id'] ?? 0);
$receitaId = (int) ($dados['receita_id'] ?? 0);

if (!$grupoId || !$receitaId) {
    responder(false, 'Informe o grupo e a receita.', [], 422);
}

$chkGrupo = $pdo->prepare("SELECT id FROM FS_grupos_biblioteca WHERE id = ? AND usuario_id = ?");
$chkGrupo->execute([$grupoId, $uid]);
if (!$chkGrupo->fetch()) {
    responder(false, 'Grupo não encontrado.', [], 404);
}

$chkReceita = $pdo->prepare("SELECT id FROM FS_biblioteca_receitas WHERE id = ?");
$chkReceita->execute([$receitaId]);
if (!$chkReceita->fetch()) {
    responder(false, 'Receita não encontrada.', [], 404);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $stmt = $pdo->prepare("INSERT IGNORE INTO FS_grupo_biblioteca (grupo_id, receita_id) VALUES (?, ?)");
    $stmt->execute([$grupoId, $receitaId]);
    responder(true, 'Receita adicionada ao grupo.');
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $stmt = $pdo->prepare("DELETE FROM FS_grupo_biblioteca WHERE grupo_id = ? AND receita_id = ?");
    $stmt->execute([$grupoId, $receitaId]);
    responder(true, 'Receita removida do grupo.');
}

responder(false, 'Método HTTP não permitido.', [], 405);
