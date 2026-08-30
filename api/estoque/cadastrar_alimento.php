<?php
// Cadastra um novo alimento no estoque do usuário logado.
// A quantidade mínima (pra lista de compras automática) não é definida
// aqui — vive em FS_minimos_alimento, por nome, independente do estoque
// (ver api/estoque/definir_minimo.php).
//
// Só junta com um alimento já existente (soma a quantidade em vez de criar
// linha nova) quando nome, unidade E validade são TODOS iguais — ou seja,
// quando é realmente o mesmo lote. Nome igual com validade diferente é um
// lote novo (ex.: comprou mais banana, mas com vencimento diferente do que
// já tinha) e continua virando uma linha separada, de propósito.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados         = corpoRequisicao();
$nome          = trim($dados['nome'] ?? '');
$quantidadeStr = trim((string) ($dados['quantidade'] ?? ''));
$unidade       = trim($dados['unidade'] ?? 'kg');
$validade      = trim($dados['validade'] ?? '');

if (!$nome || !$quantidadeStr || !$validade) {
    responder(false, 'Preencha todos os campos.', [], 422);
}

$quantidade = normalizarDecimal($quantidadeStr);
if ($quantidade === null || $quantidade <= 0) {
    responder(false, 'Informe uma quantidade válida.', [], 422);
}

$pdo->beginTransaction();
try {
    // Só é "o mesmo item" se nome, unidade e validade batem exatamente —
    // aí sim soma a quantidade em vez de criar linha nova.
    $stmtExistente = $pdo->prepare(
        "SELECT id FROM FS_alimentos
         WHERE usuario_id = ? AND LOWER(TRIM(descricao)) = LOWER(TRIM(?))
           AND unidade_medida = ? AND data_validade = ?"
    );
    $stmtExistente->execute([$uid, $nome, $unidade, $validade]);
    $existente = $stmtExistente->fetch();

    $mesclado = false;

    if ($existente) {
        $stmtUpd = $pdo->prepare("UPDATE FS_alimentos SET quantidade = quantidade + ? WHERE id = ?");
        $stmtUpd->execute([$quantidade, $existente['id']]);

        $novoId   = (int) $existente['id'];
        $mesclado = true;
    } else {
        $stmt = $pdo->prepare(
            "INSERT INTO FS_alimentos (usuario_id, descricao, quantidade, unidade_medida, data_validade) VALUES (?, ?, ?, ?, ?)"
        );
        $stmt->execute([$uid, $nome, $quantidade, $unidade, $validade]);
        $novoId = (int) $pdo->lastInsertId();
    }

    // Se o alimento cadastrado corresponde a algo que já estava pendente na
    // lista de compras (mesmo nome, ainda não marcado como comprado), marca
    // esse(s) item(ns) como comprado — cadastrar o alimento no estoque já é
    // a confirmação de que ele foi comprado.
    $stmtLista = $pdo->prepare(
        "UPDATE FS_lista_compras SET comprado = 1
         WHERE usuario_id = ? AND comprado = 0 AND LOWER(TRIM(nome_alimento)) = LOWER(TRIM(?))"
    );
    $stmtLista->execute([$uid, $nome]);

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    responder(false, 'Erro ao cadastrar alimento.', [], 500);
}

responder(true, $mesclado ? 'Quantidade somada ao item já existente no estoque!' : 'Item adicionado!', ['id' => $novoId, 'mesclado' => $mesclado]);
