<?php
// Funções e bootstrap comuns a todos os endpoints da API.
// Inclui sessão, conexão PDO e helpers de resposta/validação.

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

header('Content-Type: application/json; charset=utf-8');

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
 * Lê o corpo da requisição (JSON) e retorna como array associativo.
 * Aceita também dados enviados via form-urlencoded ($_POST) como fallback.
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
 * Garante que existe uma sessão de usuário válida.
 * Encerra a requisição com 401 caso não haja.
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
 * Converte um valor numérico digitado pelo usuário para float, aceitando
 * tanto ponto quanto vírgula como separador decimal (ex.: "2,5" ou "2.5").
 * Sem isso, (float) trunca "2,5" em 2.0 silenciosamente. Retorna null se
 * o valor estiver vazio ou não for um número válido.
 */
function normalizarDecimal($valor): ?float
{
    $valor = str_replace(',', '.', trim((string) $valor));
    if ($valor === '' || !is_numeric($valor)) {
        return null;
    }
    return (float) $valor;
}
