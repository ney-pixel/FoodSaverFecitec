<?php
// Lista as receitas do usuário logado, com os ingredientes vinculados.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

$stmt = $pdo->prepare(
    "SELECT fr.id, fr.titulo, fr.descricao, fr.porcoes, fr.modo_preparo, fr.favorito, fr.criado_em,
            GROUP_CONCAT(fa.descricao SEPARATOR '||') AS ingredientes_str
     FROM FS_receitas fr
     LEFT JOIN FS_receita_alimentos fra ON fra.receita_id = fr.id
     LEFT JOIN FS_alimentos fa ON fa.id = fra.alimento_id
     WHERE fr.usuario_id = ?
     GROUP BY fr.id
     ORDER BY fr.criado_em DESC"
);
$stmt->execute([$uid]);

$receitas = [];
while ($row = $stmt->fetch()) {
    $receitas[] = [
        'id'           => (int) $row['id'],
        'titulo'       => $row['titulo'],
        'descricao'    => $row['descricao'],
        'porcoes'      => (int) $row['porcoes'],
        'modo_preparo' => $row['modo_preparo'],
        'favorito'     => (bool) $row['favorito'],
        'criado_em'    => $row['criado_em'],
        'ingredientes' => $row['ingredientes_str'] ? explode('||', $row['ingredientes_str']) : [],
    ];
}

responder(true, '', ['receitas' => $receitas]);
