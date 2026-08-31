<?php
// Bootstrap comum a todos os endpoints da API.

// Nunca imprime erro/aviso/exceção na resposta; registra no log e devolve JSON genérico.
ini_set('display_errors', '0');
error_reporting(E_ALL);

set_error_handler(function (int $codigo, string $mensagem, string $arquivo, int $linha): bool {
    error_log("[PHP] $mensagem em $arquivo:$linha");
    return true; // impede o handler padrão de também imprimir o erro
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

// CORS: permite chamadas de outra origem (ex: Flutter Web), com credenciais.
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header('Access-Control-Allow-Origin: ' . $_SERVER['HTTP_ORIGIN']);
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
}
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // Preflight do navegador
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/conexao.php';

/**
 * Envia uma resposta JSON padronizada e encerra o script.
 */
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

/**
 * Lê o corpo da requisição (JSON, com fallback para $_POST).
 */
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

/**
 * Garante que existe uma sessão de usuário válida (401 caso não haja).
 */
function exigirLogin(): int
{
    if (!isset($_SESSION['usuario_id'])) {
        responder(false, 'Sessão expirada. Faça login novamente.', [], 401);
    }
    return (int) $_SESSION['usuario_id'];
}

/**
 * Garante que o método HTTP da requisição está entre os permitidos.
 */
function exigirMetodo(array $metodos): void
{
    if (!in_array($_SERVER['REQUEST_METHOD'], $metodos, true)) {
        responder(false, 'Método HTTP não permitido.', [], 405);
    }
}

/**
 * Converte para float aceitando ponto ou vírgula como decimal.
 */
function normalizarDecimal($valor): ?float
{
    $valor = str_replace(',', '.', trim((string) $valor));
    if ($valor === '' || !is_numeric($valor)) {
        return null;
    }
    return (float) $valor;
}

/**
 * Converte uma quantidade entre unidades compatíveis (só massa, por ora).
 */
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
