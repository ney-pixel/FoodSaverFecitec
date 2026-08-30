<?php
// Lista os alimentos do estoque do usuário logado, com a quantidade
// mínima (se definida) e informações de validade já calculadas
// (mesma lógica que existia em perfil.php: diasValidade/classeValidade/textoValidade).

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

function diasValidade(string $validade): int
{
    $hoje = new DateTime('today');
    $val  = new DateTime($validade);
    return (int) $hoje->diff($val)->days * ($val >= $hoje ? 1 : -1);
}
function classeValidade(int $dias): string
{
    if ($dias < 0) return 'danger';
    if ($dias <= 2) return 'warning';
    return 'good';
}
function textoValidade(int $dias): string
{
    if ($dias < 0) return 'Vencido há ' . abs($dias) . ' dia(s)';
    return 'Vence em ' . $dias . ' dia(s)';
}

$stmt = $pdo->prepare(
    "SELECT a.id, a.descricao AS nome, a.quantidade, a.unidade_medida AS unidade,
            a.data_validade AS validade
     FROM FS_alimentos a
     WHERE a.usuario_id = ?
     ORDER BY a.data_validade ASC"
);
$stmt->execute([$uid]);

$alimentos = [];
while ($row = $stmt->fetch()) {
    $dias = diasValidade($row['validade']);
    $alimentos[] = [
        'id'                => (int) $row['id'],
        'nome'              => $row['nome'],
        'quantidade'        => (float) $row['quantidade'],
        'unidade'           => $row['unidade'],
        'validade'          => $row['validade'],
        'dias_validade'     => $dias,
        'classe_validade'   => classeValidade($dias),
        'texto_validade'    => textoValidade($dias),
    ];
}

responder(true, '', ['alimentos' => $alimentos]);
