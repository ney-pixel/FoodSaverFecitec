<?php
// ─────────────────────────────────────────────
//  Relatórios
//  GET ?periodo=7 | 30 | 90
//
//  Retorna em uma única requisição:
//   1. resumo_estoque
//   2. desperdicio_por_dia   (gráfico)
//   3. top_desperdicados
//   4. top_consumidos
//   5. situacao_validades
//   6. taxa_aproveitamento
//   7. comparacao_periodo_anterior
// ─────────────────────────────────────────────

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

// Período selecionado (dias): 7, 30 ou 90 (default 30)
$periodosValidos = [7, 30, 90];
$periodo = (int) ($_GET['periodo'] ?? 30);
if (!in_array($periodo, $periodosValidos, true)) {
    $periodo = 30;
}

// Datas do período atual e anterior
$hoje         = new DateTime('today');
$inicioAtual  = (clone $hoje)->modify("-{$periodo} days")->format('Y-m-d');
$fimAtual     = $hoje->format('Y-m-d');
$inicioPrev   = (clone $hoje)->modify('-' . ($periodo * 2) . ' days')->format('Y-m-d');
$fimPrev      = (clone $hoje)->modify("-{$periodo} days")->format('Y-m-d');

// ─────────────────────────────────────────────
//  1. RESUMO DO ESTOQUE
// ─────────────────────────────────────────────

// Total de alimentos no estoque
$stmtTotal = $pdo->prepare(
    "SELECT COUNT(*) AS total FROM FS_alimentos WHERE usuario_id = ?"
);
$stmtTotal->execute([$uid]);
$totalEstoque = (int) $stmtTotal->fetchColumn();

// Vencidos (data_validade < hoje)
$stmtVenc = $pdo->prepare(
    "SELECT COUNT(*) FROM FS_alimentos
     WHERE usuario_id = ? AND data_validade < CURDATE()"
);
$stmtVenc->execute([$uid]);
$vencidos = (int) $stmtVenc->fetchColumn();

// Próximos do vencimento (até 7 dias)
$stmtProx = $pdo->prepare(
    "SELECT COUNT(*) FROM FS_alimentos
     WHERE usuario_id = ?
       AND data_validade >= CURDATE()
       AND data_validade <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)"
);
$stmtProx->execute([$uid]);
$proximosVencimento = (int) $stmtProx->fetchColumn();

// Total desperdiçado (all time)
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

// ─────────────────────────────────────────────
//  2. DESPERDÍCIO POR DIA (período atual)
// ─────────────────────────────────────────────

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

// Preenche dias sem movimentação com 0 (sem lacunas no gráfico)
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

// ─────────────────────────────────────────────
//  3. ALIMENTOS MAIS DESPERDIÇADOS (período)
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  4. ALIMENTOS MAIS CONSUMIDOS (período)
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  5. SITUAÇÃO DAS VALIDADES
// ─────────────────────────────────────────────

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
    'vencidos'   => [],   // dias < 0
    'ate3dias'   => [],   // 0 <= dias <= 3
    'ate7dias'   => [],   // 4 <= dias <= 7
    'ok'         => [],   // dias > 7
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

// ─────────────────────────────────────────────
//  6. TAXA DE APROVEITAMENTO (período atual)
// ─────────────────────────────────────────────

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
    : null; // null = sem dados suficientes

$taxaAproveitamento = [
    'consumido'    => $consumidoAtual,
    'desperdicado' => $desperdicadoAtual,
    'taxa'         => $taxaAtual,      // null se sem dados
];

// ─────────────────────────────────────────────
//  7. COMPARAÇÃO COM PERÍODO ANTERIOR
// ─────────────────────────────────────────────

// Desperdício período anterior
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

// Taxa de aproveitamento período anterior
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

// Variação de desperdício (%)
$variacaoDesp = null;
if ($desperdicadoPrev > 0) {
    $variacaoDesp = round((($desperdicadoAtual - $desperdicadoPrev) / $desperdicadoPrev) * 100, 1);
}

// Variação da taxa de aproveitamento (pontos percentuais)
$variacaoTaxa = ($taxaAtual !== null && $taxaPrev !== null)
    ? round($taxaAtual - $taxaPrev, 1)
    : null;

$comparacao = [
    'desperdicio_atual'    => $desperdicadoAtual,
    'desperdicio_anterior' => $desperdicadoPrev,
    'variacao_desperdicio' => $variacaoDesp,   // % (negativo = melhora)
    'taxa_atual'           => $taxaAtual,
    'taxa_anterior'        => $taxaPrev,
    'variacao_taxa'        => $variacaoTaxa,   // pp (positivo = melhora)
];

// ─────────────────────────────────────────────
//  RESPOSTA FINAL
// ─────────────────────────────────────────────

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