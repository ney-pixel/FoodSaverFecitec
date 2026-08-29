<?php
// Favorita ou desfavorita uma receita gerada por IA.
//
// Diferente de biblioteca/favoritar_biblioteca.php: a receita da IA só
// existe no banco quando favoritada — não tem id ainda na primeira vez
// (a geração em ia/gerar_receita.php não salva nada).
//   - Se o corpo trouxer "id" > 0: a receita já estava salva -> desfavoritar = apaga a linha.
//   - Se não trouxer id (ou vier 0): ainda não existe -> favoritar = insere com os dados enviados.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
$uid = exigirLogin();

$dados = corpoRequisicao();
$id    = (int) ($dados['id'] ?? 0);

if ($id > 0) {
    $stmt = $pdo->prepare("DELETE FROM FS_receitas_ia WHERE id = ? AND usuario_id = ?");
    $stmt->execute([$id, $uid]);
    if ($stmt->rowCount() === 0) {
        responder(false, 'Receita não encontrada.', [], 404);
    }
    responder(true, 'Receita removida dos favoritos.', ['favorito' => false, 'id' => 0]);
}

// Ainda não existe: favoritar = inserir com os dados da receita gerada.
$titulo      = trim($dados['titulo'] ?? '');
$modoPreparo = $dados['modo_preparo'] ?? [];

if (!$titulo || !is_array($modoPreparo) || empty($modoPreparo)) {
    responder(false, 'Dados da receita incompletos.', [], 422);
}

$juntar = fn ($v) => is_array($v) ? implode('||', array_map('strval', $v)) : '';

$stmt = $pdo->prepare(
    "INSERT INTO FS_receitas_ia
        (usuario_id, titulo, descricao, categoria, dificuldade, tempo_preparo, porcoes, calorias, imagem, ingredientes, ingredientes_necessarios, modo_preparo, dicas)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
);
$stmt->execute([
    $uid,
    $titulo,
    trim($dados['descricao'] ?? ''),
    trim($dados['categoria'] ?? ''),
    trim($dados['dificuldade'] ?? 'Fácil'),
    (int) ($dados['tempo_preparo'] ?? 0),
    (int) ($dados['porcoes'] ?? 1),
    (int) ($dados['calorias'] ?? 0),
    trim($dados['imagem'] ?? ''),
    $juntar($dados['ingredientes'] ?? []),
    $juntar($dados['ingredientes_necessarios'] ?? []),
    $juntar($modoPreparo),
    $juntar($dados['dicas'] ?? []),
]);

responder(true, 'Receita adicionada aos favoritos.', [
    'favorito' => true,
    'id'       => (int) $pdo->lastInsertId(),
]);
