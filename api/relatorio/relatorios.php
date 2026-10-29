<?php
//relatorios

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

//periodo (7, 30 ou 90 dias)
$periodosValidos = [7, 30, 90];
$periodo = (int) ($_GET['periodo'] ?? 30);
if (!in_array($periodo, $periodosValidos, true)) {
    $periodo = 30;
}

$hoje         = new DateTime('today');
$inicioAtual  = (clone $hoje)->modify("-{$periodo} days")->format('Y-m-d');
$fimAtual     = $hoje->format('Y-m-d');
$inicioPrev   = (clone $hoje)->modify('-' . ($periodo * 2) . ' days')->format('Y-m-d');
$fimPrev      = (clone $hoje)->modify("-{$periodo} days")->format('Y-m-d');

//1. resumo do estoque

$stmtTotal = $pdo->prepare(
    "SELECT COUNT(*) AS total FROM FS_alimentos WHERE usuario_id = ?"
);
$stmtTotal->execute([$uid]);
$totalEstoque = (int) $stmtTotal->fetchColumn();

//vencidos
$stmtVenc = $pdo->prepare(
    "SELECT COUNT(*) FROM FS_alimentos
     WHERE usuario_id = ? AND data_validade < CURDATE()"
);
$stmtVenc->execute([$uid]);
$vencidos = (int) $stmtVenc->fetchColumn();

//vencem em ate 7 dias
$stmtProx = $pdo->prepare(
    "SELECT COUNT(*) FROM FS_alimentos
     WHERE usuario_id = ?
       AND data_validade >= CURDATE()
       AND data_validade <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)"
);
$stmtProx->execute([$uid]);
$proximosVencimento = (int) $stmtProx->fetchColumn();

//total desperdicado
$stmtDesp = $pdo->prepare(
    "SELECT COALESCE(SUM(quantidade), 0)
     FROM FS_movimentacoes
     WHERE usuario_id = ? AND tipo = 'desperdicio'"
);
$stmtDesp->execute([$uid]);
$totalDesperdicio = (float) $stmtDesp->fetchColumn();

$resumoEstoque = [
    'total_alimentos'      => $totalEstoque,
    'vencidos'             => $vencidos,
    'proximos_vencimento'  => $proximosVencimento,
    'total_desperdicado'   => $totalDesperdicio,
];

//2. desperdicio por dia

$stmtGraf = $pdo->prepare(
    "SELECT DATE(data_movimentacao) AS dia,
            SUM(quantidade)         AS total
     FROM FS_movimentacoes
     WHERE usuario_id = ?
       AND tipo = 'desperdicio'
       AND data_movimentacao >= ?
       AND data_movimentacao <  DATE_ADD(?, INTERVAL 1 DAY)
     GROUP BY dia
     ORDER BY dia ASC"
);
$stmtGraf->execute([$uid, $inicioAtual, $fimAtual]);

$mapaDias = [];
$cursor = new DateTime($inicioAtual);
$fim    = new DateTime($fimAtual);
while ($cursor <= $fim) {
    $mapaDias[$cursor->format('Y-m-d')] = 0.0;
    $cursor->modify('+1 day');
}
while ($row = $stmtGraf->fetch()) {
    $mapaDias[$row['dia']] = (float) $row['total'];
}

$desperdicoPorDia = [];
foreach ($mapaDias as $dia => $total) {
    $desperdicoPorDia[] = ['dia' => $dia, 'total' => $total];
}

//3. mais desperdicados

$stmtTopDesp = $pdo->prepare(
    "SELECT m.descricao_alimento AS nome,
            m.unidade_medida     AS unidade,
            SUM(m.quantidade)    AS total
     FROM FS_movimentacoes m
     WHERE m.usuario_id = ?
       AND m.tipo = 'desperdicio'
       AND m.data_movimentacao >= ?
       AND m.data_movimentacao <  DATE_ADD(?, INTERVAL 1 DAY)
     GROUP BY m.descricao_alimento, m.unidade_medida
     ORDER BY total DESC
     LIMIT 8"
);
$stmtTopDesp->execute([$uid, $inicioAtual, $fimAtual]);
$topDesperdicados = $stmtTopDesp->fetchAll();

foreach ($topDesperdicados as &$item) {
    $item['total'] = (float) $item['total'];
}
unset($item);

//4. mais consumidos

$stmtTopCons = $pdo->prepare(
    "SELECT m.descricao_alimento AS nome,
            m.unidade_medida     AS unidade,
            SUM(m.quantidade)    AS total
     FROM FS_movimentacoes m
     WHERE m.usuario_id = ?
       AND m.tipo = 'consumo'
       AND m.data_movimentacao >= ?
       AND m.data_movimentacao <  DATE_ADD(?, INTERVAL 1 DAY)
     GROUP BY m.descricao_alimento, m.unidade_medida
     ORDER BY total DESC
     LIMIT 8"
);
$stmtTopCons->execute([$uid, $inicioAtual, $fimAtual]);
$topConsumidos = $stmtTopCons->fetchAll();

foreach ($topConsumidos as &$item) {
    $item['total'] = (float) $item['total'];
}
unset($item);

//5. situacao das validades

$stmtVal = $pdo->prepare(
    "SELECT descricao,
            data_validade,
            quantidade,
            unidade_medida,
            DATEDIFF(data_validade, CURDATE()) AS dias
     FROM FS_alimentos
     WHERE usuario_id = ?
     ORDER BY data_validade ASC"
);
$stmtVal->execute([$uid]);
$todosAlimentos = $stmtVal->fetchAll();

$validades = [
    'vencidos'   => [],
    'ate3dias'   => [],
    'ate7dias'   => [],
    'ok'         => [],
];

foreach ($todosAlimentos as $a) {
    $dias = (int) $a['dias'];
    $item = [
        'nome'      => $a['descricao'],
        'validade'  => $a['data_validade'],
        'quantidade'=> (float) $a['quantidade'],
        'unidade'   => $a['unidade_medida'],
        'dias'      => $dias,
    ];

    if ($dias < 0)       $validades['vencidos'][] = $item;
    elseif ($dias <= 3)  $validades['ate3dias'][]  = $item;
    elseif ($dias <= 7)  $validades['ate7dias'][]  = $item;
    else                 $validades['ok'][]         = $item;
}

//6. taxa de aproveitamento

$stmtTaxa = $pdo->prepare(
    "SELECT tipo, SUM(quantidade) AS total
     FROM FS_movimentacoes
     WHERE usuario_id = ?
       AND tipo IN ('consumo', 'desperdicio')
       AND data_movimentacao >= ?
       AND data_movimentacao <  DATE_ADD(?, INTERVAL 1 DAY)
     GROUP BY tipo"
);
$stmtTaxa->execute([$uid, $inicioAtual, $fimAtual]);

$consumidoAtual    = 0.0;
$desperdicadoAtual = 0.0;
while ($row = $stmtTaxa->fetch()) {
    if ($row['tipo'] === 'consumo')     $consumidoAtual    = (float) $row['total'];
    if ($row['tipo'] === 'desperdicio') $desperdicadoAtual = (float) $row['total'];
}

$somaAtual = $consumidoAtual + $desperdicadoAtual;
$taxaAtual = $somaAtual > 0
    ? round(($consumidoAtual / $somaAtual) * 100, 1)
    : null;

$taxaAproveitamento = [
    'consumido'    => $consumidoAtual,
    'desperdicado' => $desperdicadoAtual,
    'taxa'         => $taxaAtual,
];

//7. comparacao com periodo anterior

$stmtPrevDesp = $pdo->prepare(
    "SELECT COALESCE(SUM(quantidade), 0)
     FROM FS_movimentacoes
     WHERE usuario_id = ?
       AND tipo = 'desperdicio'
       AND data_movimentacao >= ?
       AND data_movimentacao <  DATE_ADD(?, INTERVAL 1 DAY)"
);
$stmtPrevDesp->execute([$uid, $inicioPrev, $fimPrev]);
$desperdicadoPrev = (float) $stmtPrevDesp->fetchColumn();

$stmtPrevTaxa = $pdo->prepare(
    "SELECT tipo, SUM(quantidade) AS total
     FROM FS_movimentacoes
     WHERE usuario_id = ?
       AND tipo IN ('consumo', 'desperdicio')
       AND data_movimentacao >= ?
       AND data_movimentacao <  DATE_ADD(?, INTERVAL 1 DAY)
     GROUP BY tipo"
);
$stmtPrevTaxa->execute([$uid, $inicioPrev, $fimPrev]);

$consumidoPrev    = 0.0;
$desperdicadoPrev2 = 0.0;
while ($row = $stmtPrevTaxa->fetch()) {
    if ($row['tipo'] === 'consumo')     $consumidoPrev     = (float) $row['total'];
    if ($row['tipo'] === 'desperdicio') $desperdicadoPrev2 = (float) $row['total'];
}
$somaPrev = $consumidoPrev + $desperdicadoPrev2;
$taxaPrev = $somaPrev > 0
    ? round(($consumidoPrev / $somaPrev) * 100, 1)
    : null;

$variacaoDesp = null;
if ($desperdicadoPrev > 0) {
    $variacaoDesp = round((($desperdicadoAtual - $desperdicadoPrev) / $desperdicadoPrev) * 100, 1);
}

$variacaoTaxa = ($taxaAtual !== null && $taxaPrev !== null)
    ? round($taxaAtual - $taxaPrev, 1)
    : null;

$comparacao = [
    'desperdicio_atual'    => $desperdicadoAtual,
    'desperdicio_anterior' => $desperdicadoPrev,
    'variacao_desperdicio' => $variacaoDesp,
    'taxa_atual'           => $taxaAtual,
    'taxa_anterior'        => $taxaPrev,
    'variacao_taxa'        => $variacaoTaxa,
];

//resposta

responder(true, '', [
    'periodo'              => $periodo,
    'resumo_estoque'       => $resumoEstoque,
    'desperdicio_por_dia'  => $desperdicoPorDia,
    'top_desperdicados'    => $topDesperdicados,
    'top_consumidos'       => $topConsumidos,
    'situacao_validades'   => $validades,
    'taxa_aproveitamento'  => $taxaAproveitamento,
    'comparacao'           => $comparacao,
]);