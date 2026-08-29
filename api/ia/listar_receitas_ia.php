<?php
// Lista as receitas geradas por IA que o usuário logado favoritou
// (a existência da linha em FS_receitas_ia já significa "favoritada" —
// ver ia/favoritar_receita_ia.php).

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

$stmt = $pdo->prepare(
    "SELECT id, titulo, descricao, categoria, dificuldade, tempo_preparo, porcoes, calorias, imagem,
            ingredientes, ingredientes_necessarios, modo_preparo, dicas
     FROM FS_receitas_ia WHERE usuario_id = ? ORDER BY criado_em DESC"
);
$stmt->execute([$uid]);

$receitas = [];
while ($row = $stmt->fetch()) {
    $receitas[] = [
        'id'                       => (int) $row['id'],
        'titulo'                   => $row['titulo'],
        'descricao'                => $row['descricao'],
        'categoria'                => $row['categoria'],
        'dificuldade'              => $row['dificuldade'],
        'tempo_preparo'            => (int) $row['tempo_preparo'],
        'porcoes'                  => (int) $row['porcoes'],
        'calorias'                 => (int) $row['calorias'],
        'imagem'                   => $row['imagem'],
        'ingredientes'             => $row['ingredientes'] ? explode('||', $row['ingredientes']) : [],
        'ingredientes_necessarios' => $row['ingredientes_necessarios'] ? explode('||', $row['ingredientes_necessarios']) : [],
        'modo_preparo'             => $row['modo_preparo'] ? explode('||', $row['modo_preparo']) : [],
        'dicas'                    => $row['dicas'] ? explode('||', $row['dicas']) : [],
        'favorito'                 => true,
        'gerada_por_ia'            => true,
    ];
}

responder(true, '', ['receitas' => $receitas]);
