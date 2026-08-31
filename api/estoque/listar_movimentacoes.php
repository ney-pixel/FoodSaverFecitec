<?php
// Resumo das movimentações (consumo/desperdício) para os gráficos de Relatórios.

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['GET']);
$uid = exigirLogin();

$dias = 30;

$stmt = $pdo->prepare(
    "SELECT DATE(data_movimentacao) AS dia, tipo, COUNT(*) AS qtd
     FROM FS_movimentacoes
     WHERE usuario_id = ? AND tipo IN ('consumo', 'desperdicio')
       AND data_movimentacao >= (CURDATE() - INTERVAL ? DAY)
     GROUP BY DATE(data_movimentacao), tipo"
);
$stmt->execute([$uid, $dias - 1]);

$porDia = [];
foreach ($stmt->fetchAll() as $row) {
    $porDia[$row['dia']][$row['tipo']] = (int) $row['qtd'];
}

$serie = [];
$totalConsumo = 0;
$totalDesperdicio = 0;
for ($i = $dias - 1; $i >= 0; $i--) {
    $data = (new DateTime())->modify("-{$i} days")->format('Y-m-d');
    $consumo = $porDia[$data]['consumo'] ?? 0;
    $desperdicio = $porDia[$data]['desperdicio'] ?? 0;
    $serie[] = ['data' => $data, 'consumo' => $consumo, 'desperdicio' => $desperdicio];
    $totalConsumo += $consumo;
    $totalDesperdicio += $desperdicio;
}

$totalMovs = $totalConsumo + $totalDesperdicio;
$taxaAproveitamento = $totalMovs > 0 ? round(($totalConsumo / $totalMovs) * 100, 1) : null;

// Ranking por alimento (nome + unidade)
$nomeSql = "COALESCE(NULLIF(TRIM(descricao_alimento), ''), 'Item removido') AS nome";

$stmtConsumido = $pdo->prepare(
    "SELECT {$nomeSql}, unidade_medida AS unidade, COUNT(*) AS eventos, SUM(quantidade) AS quantidade
     FROM FS_movimentacoes
     WHERE usuario_id = ? AND tipo = 'consumo'
       AND data_movimentacao >= (CURDATE() - INTERVAL ? DAY)
     GROUP BY nome, unidade_medida
     ORDER BY eventos DESC, quantidade DESC
     LIMIT 1"
);
$stmtConsumido->execute([$uid, $dias - 1]);
$maisConsumido = $stmtConsumido->fetch() ?: null;
if ($maisConsumido) {
    $maisConsumido['eventos'] = (int) $maisConsumido['eventos'];
    $maisConsumido['quantidade'] = (float) $maisConsumido['quantidade'];
}

responder(true, '', [
    'serie_dias'          => $serie,
    'total_consumo'       => $totalConsumo,
    'total_desperdicio'   => $totalDesperdicio,
    'taxa_aproveitamento' => $taxaAproveitamento,
    'mais_consumido'      => $maisConsumido,
]);
