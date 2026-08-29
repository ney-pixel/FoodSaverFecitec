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
        "SELECT nome_alimento, quantidade, unidade_medida, comprado FROM FS_lista_compras WHERE id = ? AND usuario_id = ?"
    );
    $stmtItem->execute([$id, $uid]);
    $item = $stmtItem->fetch();
    if (!$item) {
        responder(false, 'Item não encontrado.', [], 404);
    }

    $novoComprado = !((bool) $item['comprado']);

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("UPDATE FS_lista_compras SET comprado = ? WHERE id = ? AND usuario_id = ?");
        $stmt->execute([$novoComprado ? 1 : 0, $id, $uid]);

        // Só reflete no estoque quando o item está sendo marcado como
        // comprado agora (não ao desmarcar) — comprar atualiza o inventário;
        // desmarcar por engano não deve tirar quantidade que já pode ter
        // sido usada/mexida no estoque desde então.
        //
        // Sempre cria um alimento novo (não soma num já existente): a lista
        // de compras não tem data de validade, então não dá pra saber se é
        // o mesmo lote de algo que já está no estoque. Somar ali poderia
        // misturar quantidades com validades diferentes sob uma validade só.
        // Como validade é obrigatória em FS_alimentos, usamos um padrão de
        // 7 dias — o usuário ajusta depois em "Editar" no inventário.
        if ($novoComprado) {
            $validadePadrao = (new DateTime('today'))->modify('+7 days')->format('Y-m-d');
            $stmtIns = $pdo->prepare(
                "INSERT INTO FS_alimentos (usuario_id, descricao, quantidade, unidade_medida, data_validade) VALUES (?, ?, ?, ?, ?)"
            );
            $stmtIns->execute([$uid, $item['nome_alimento'], $item['quantidade'], $item['unidade_medida'], $validadePadrao]);
        }

        $pdo->commit();
    } catch (PDOException $e) {
        $pdo->rollBack();
        responder(false, 'Erro ao atualizar status.', [], 500);
    }

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
