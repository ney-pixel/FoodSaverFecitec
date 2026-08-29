<?php
// Funções e bootstrap comuns a todos os endpoints da API.
// Inclui sessão, conexão PDO e helpers de resposta/validação.

// Blindagem: qualquer erro/aviso/exceção do PHP que não seja tratado pelo
// próprio endpoint NUNCA deve ser impresso na resposta (isso quebraria o
// JSON e o app receberia "resposta inválida do servidor"). Em vez disso,
// registramos no log do servidor (visível no terminal onde o `php -S`
// está rodando) e devolvemos um JSON de erro genérico.
ini_set('display_errors', '0');
error_reporting(E_ALL);

set_error_handler(function (int $codigo, string $mensagem, string $arquivo, int $linha): bool {
    error_log("[PHP] $mensagem em $arquivo:$linha");
    return true; // impede o handler padrão do PHP de também imprimir o erro
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

// CORS: necessário quando quem chama a API roda em outra origem (porta)
// da mesma máquina — por exemplo o Flutter em modo Web/Chrome (ex:
// http://localhost:5000) enquanto a API roda em http://localhost:8000.
// Apps nativos (Android/iOS/Windows) ignoram CORS e não são afetados.
// Como a sessão usa cookie, é obrigatório ecoar a origem específica (e
// não "*") e habilitar credenciais.
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header('Access-Control-Allow-Origin: ' . $_SERVER['HTTP_ORIGIN']);
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
}
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // Requisição de "preflight" do navegador: só confirma os cabeçalhos acima.
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

/**
 * Converte uma quantidade entre unidades compatíveis (só massa, por ora).
 * Unidades iguais sempre "convertem" 1:1. Retorna null se não for possível
 * (unidades incompatíveis, ex.: "kg" para "un").
 * Compartilhada entre movimentar_alimento.php e editar_compra.php.
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
