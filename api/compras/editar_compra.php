<?php
// Edita um item da lista de compras do usuário logado.
// Como a especificação não prevê um arquivo separado para marcar como
// comprado ou remover, essas ações (que já existiam em perfil.php) ficam
// aqui, diferenciadas pelo método HTTP:
//   PUT/POST -> edita nome/quantidade/unidade
//   PATCH    -> alterna comprado/não comprado
//   DELETE   -> remove o item

require_once __DIR__ . '/../helpers.php';

$uid = exigirLogin();
$metodo = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'DELETE') {
    $dados = corpoRequisicao();
    $id    = (int) ($dados['id'] ?? $_GET['id'] ?? 0);
    if (!$id) {
        responder(false, 'Informe o item a ser removido.', [], 422);
    }
    $stmt = $pdo->prepare("DELETE FROM FS_lista_compras WHERE id = ? AND usuario_id = ?");
    $stmt->execute([$id, $uid]);
    if ($stmt->rowCount() === 0) {
        responder(false, 'Item não encontrado.', [], 404);
    }
    responder(true, 'Item removido da lista.');
}

if ($metodo === 'PATCH') {
    $dados = corpoRequisicao();
    $id    = (int) ($dados['id'] ?? 0);
    if (!$id) {
        responder(false, 'Informe o item.', [], 422);
    }

    $stmtItem = $pdo->prepare(
        "SELECT comprado FROM FS_lista_compras WHERE id = ? AND usuario_id = ?"
    );
    $stmtItem->execute([$id, $uid]);
    $item = $stmtItem->fetch();
    if (!$item) {
        responder(false, 'Item não encontrado.', [], 404);
    }

    // Só alterna a marcação de "comprado" — não mexe no estoque. O item só
    // entra de fato no inventário quando o usuário confirma em "Concluir"
    // (ver concluir_compras.php), onde ele informa a validade de cada um.
    $novoComprado = !((bool) $item['comprado']);
    $stmt = $pdo->prepare("UPDATE FS_lista_compras SET comprado = ? WHERE id = ? AND usuario_id = ?");
    $stmt->execute([$novoComprado ? 1 : 0, $id, $uid]);

    responder(true, 'Status atualizado.');
}

if ($metodo === 'POST' || $metodo === 'PUT') {
    $dados         = corpoRequisicao();
    $id            = (int) ($dados['id'] ?? 0);
    $nomeAlimento  = trim($dados['nome_alimento'] ?? '');
    $quantidadeStr = trim((string) ($dados['quantidade'] ?? ''));
    $unidade       = trim($dados['unidade'] ?? $dados['unidade_medida'] ?? 'kg');

    if (!$id || !$nomeAlimento || !$quantidadeStr) {
        responder(false, 'Preencha nome e quantidade.', [], 422);
    }

    $quantidade = normalizarDecimal($quantidadeStr);
    if ($quantidade === null || $quantidade <= 0) {
        responder(false, 'Informe uma quantidade válida.', [], 422);
    }

    $stmt = $pdo->prepare(
        "UPDATE FS_lista_compras SET nome_alimento=?, quantidade=?, unidade_medida=? WHERE id=? AND usuario_id=?"
    );
    $stmt->execute([$nomeAlimento, $quantidade, $unidade, $id, $uid]);

    $chk = $pdo->prepare("SELECT id FROM FS_lista_compras WHERE id = ? AND usuario_id = ?");
    $chk->execute([$id, $uid]);
    if (!$chk->fetch()) {
        responder(false, 'Item não encontrado.', [], 404);
    }

    responder(true, 'Item atualizado!');
}

responder(false, 'Método HTTP não permitido.', [], 405);
