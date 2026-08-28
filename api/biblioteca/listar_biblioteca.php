<?php
// Lista o catálogo fixo de receitas da biblioteca (imutável, mantido
// pelos desenvolvedores — não confundir com FS_receitas, que é a
// feature "Minhas Receitas" do site), com o favorito marcado por usuário.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

$stmt = $pdo->prepare(
    "SELECT b.id, b.titulo, b.descricao, b.categoria, b.dificuldade, b.tempo_preparo, b.porcoes, b.calorias, b.imagem,
            b.ingredientes, b.ingredientes_necessarios, b.modo_preparo, b.dicas,
            (f.usuario_id IS NOT NULL) AS favorito
     FROM FS_biblioteca_receitas b
     LEFT JOIN FS_biblioteca_favoritos f ON f.receita_id = b.id AND f.usuario_id = ?
     ORDER BY b.titulo ASC"
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
        'favorito'                 => (bool) $row['favorito'],
    ];
}

responder(true, '', ['receitas' => $receitas]);
