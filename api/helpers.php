<?php
//funcoes usadas por toda a API

//esconde erros do PHP na resposta
ini_set('display_errors', '0');
error_reporting(E_ALL);

set_error_handler(function (int $codigo, string $mensagem, string $arquivo, int $linha): bool {
    error_log("[PHP] $mensagem em $arquivo:$linha");
    return true;
});

set_exception_handler(function (Throwable $e): void {
    error_log('[EXCEÇÃO NÃO TRATADA] ' . $e->getMessage() . ' em ' . $e->getFile() . ':' . $e->getLine());
    if (!headers_sent()) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
    }
    echo json_encode(['sucesso' => false, 'mensagem' => 'Erro interno do servidor.']);
    exit;
});

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

header('Content-Type: application/json; charset=utf-8');

//CORS
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header('Access-Control-Allow-Origin: ' . $_SERVER['HTTP_ORIGIN']);
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
}
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/conexao.php';

//resposta JSON padrao
function responder(bool $sucesso, string $mensagem = '', array $dados = [], int $statusHttp = 200): void
{
    http_response_code($statusHttp);
    $payload = ['sucesso' => $sucesso, 'mensagem' => $mensagem];
    if (!empty($dados)) {
        $payload = array_merge($payload, $dados);
    }
    echo json_encode($payload);
    exit;
}

//le o JSON enviado
function corpoRequisicao(): array
{
    $raw = file_get_contents('php://input');
    if ($raw) {
        $json = json_decode($raw, true);
        if (is_array($json)) {
            return $json;
        }
    }
    return $_POST ?? [];
}

//exige login
function exigirLogin(): int
{
    if (!isset($_SESSION['usuario_id'])) {
        responder(false, 'Sessão expirada. Faça login novamente.', [], 401);
    }
    return (int) $_SESSION['usuario_id'];
}

//exige metodo HTTP
function exigirMetodo(array $metodos): void
{
    if (!in_array($_SERVER['REQUEST_METHOD'], $metodos, true)) {
        responder(false, 'Método HTTP não permitido.', [], 405);
    }
}

//aceita virgula ou ponto no numero
function normalizarDecimal($valor): ?float
{
    $valor = str_replace(',', '.', trim((string) $valor));
    if ($valor === '' || !is_numeric($valor)) {
        return null;
    }
    return (float) $valor;
}

//conversao de unidades
function converterQuantidade(float $qtd, string $de, string $para): ?float
{
    if ($de === $para) {
        return $qtd;
    }
    $fatoresParaGramas = ['kg' => 1000, 'g' => 1];
    if (isset($fatoresParaGramas[$de]) && isset($fatoresParaGramas[$para])) {
        return $qtd * $fatoresParaGramas[$de] / $fatoresParaGramas[$para];
    }
    return null;
}
