<?php
// Gera uma receita com IA (Gemini) a partir de ingredientes selecionados
// pelo usuário no próprio estoque, número de porções, nível de fome e
// observações opcionais.
//
// Diferente da Biblioteca (FS_biblioteca_receitas), a receita gerada aqui
// NÃO é salva no banco — é só exibida na hora. A chave da IA nunca é
// enviada ao cliente: toda a chamada ao Gemini acontece aqui no servidor.

require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/../ia_config.php';

exigirMetodo(['POST']);
exigirLogin(); // exige sessão só pra evitar uso indevido da chave por quem não é da aplicação

$dados        = corpoRequisicao();
$ingredientes = $dados['ingredientes'] ?? [];
$porcoes      = (int) ($dados['porcoes'] ?? 2);
$nivelFome    = trim($dados['nivel_fome'] ?? 'Médio');
$observacoes  = trim($dados['observacoes'] ?? '');

if (!is_array($ingredientes) || empty($ingredientes)) {
    responder(false, 'Selecione ao menos um ingrediente.', [], 422);
}
if ($porcoes < 1) {
    $porcoes = 1;
}

$listaIngredientes = implode(', ', array_map('strval', $ingredientes));
$plural            = $porcoes > 1 ? 'ões' : 'ão';

$prompt = "Você é um chef de cozinha profissional e prático, especialista em aproveitar bem os ingredientes disponíveis para reduzir desperdício de alimentos.\n"
    . "Crie uma receita usando SOMENTE ou PRINCIPALMENTE os seguintes ingredientes disponíveis: {$listaIngredientes}.\n"
    . "A receita deve servir {$porcoes} porç{$plural}.\n"
    . "Nível de fome de quem vai comer: {$nivelFome} — ajuste o tamanho e a fartura da receita de acordo com isso.\n"
    . ($observacoes !== '' ? "Observações do usuário (leve em conta se fizer sentido): {$observacoes}.\n" : '')
    . "Responda ESTRITAMENTE em JSON válido, sem markdown, sem \`\`\`, sem texto fora do JSON, no formato exato abaixo "
    . "(todos os textos em português do Brasil):\n"
    . '{"titulo":string,"descricao":string (uma frase curta),"categoria":string (ex: Massas, Carnes, Saladas, Sopas, Lanches, Bebidas, Molhos, Ovos, Pratos Principais),'
    . '"dificuldade":"Fácil" ou "Médio" ou "Difícil","tempo_preparo":numero inteiro em minutos,"porcoes":numero inteiro,'
    . '"calorias":numero inteiro (estimativa por porção),"ingredientes":[lista de strings, cada um com quantidade e medida],'
    . '"ingredientes_necessarios":[lista de strings, só o nome simples de cada ingrediente principal, sem quantidade],'
    . '"modo_preparo":[lista de strings, um passo do preparo por item, em ordem],"dicas":[lista de 1 a 3 strings com dicas úteis]}';

/**
 * Chama o Gemini via cURL e devolve o texto gerado já decodificado como array.
 * Lança RuntimeException com uma mensagem amigável em caso de falha.
 */
function chamarGeminiParaReceita(string $prompt): array
{
    $url = 'https://generativelanguage.googleapis.com/v1beta/models/'
        . GEMINI_MODELO . ':generateContent?key=' . GEMINI_API_KEY;

    $corpo = json_encode([
        'contents' => [
            ['parts' => [['text' => $prompt]]],
        ],
        'generationConfig' => [
            'responseMimeType' => 'application/json',
            'temperature'      => 0.9,
        ],
    ]);

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $corpo,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
        CURLOPT_TIMEOUT        => 45,
    ]);
    $respostaBruta = curl_exec($ch);
    $erroCurl      = curl_error($ch);
    $statusHttp    = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($respostaBruta === false || $respostaBruta === '') {
        throw new RuntimeException($erroCurl ?: 'Não foi possível conectar com a IA.');
    }

    $dados = json_decode($respostaBruta, true);

    if ($statusHttp !== 200) {
        $msg = $dados['error']['message'] ?? "A IA respondeu com erro (HTTP {$statusHttp}).";
        throw new RuntimeException($msg);
    }

    $texto = $dados['candidates'][0]['content']['parts'][0]['text'] ?? null;
    if (!$texto) {
        throw new RuntimeException('A IA não retornou nenhum conteúdo.');
    }

    $receita = json_decode($texto, true);
    if (!is_array($receita)) {
        throw new RuntimeException('A IA retornou um formato inesperado.');
    }

    return $receita;
}

try {
    $receitaIA = chamarGeminiParaReceita($prompt);
} catch (Throwable $e) {
    error_log('[IA] Falha ao gerar receita: ' . $e->getMessage());
    responder(false, 'Não foi possível gerar a receita agora. Tente novamente em instantes.', [], 502);
}

// Normaliza os campos (garante os tipos certos e preenche o que a IA
// porventura tenha deixado de fora), pra nunca quebrar o parsing no app.
$listaOuVazia = fn ($v) => is_array($v) ? array_values(array_map('strval', $v)) : [];

$receita = [
    'id'                       => 0, // não é salva no banco — sem id de verdade
    'gerada_por_ia'            => true,
    'titulo'                   => (string) ($receitaIA['titulo'] ?? 'Receita sem título'),
    'descricao'                => (string) ($receitaIA['descricao'] ?? ''),
    'categoria'                => (string) ($receitaIA['categoria'] ?? ''),
    'dificuldade'              => (string) ($receitaIA['dificuldade'] ?? 'Fácil'),
    'tempo_preparo'            => (int) ($receitaIA['tempo_preparo'] ?? 0),
    'porcoes'                  => (int) ($receitaIA['porcoes'] ?? $porcoes),
    'calorias'                 => (int) ($receitaIA['calorias'] ?? 0),
    'imagem'                   => '',
    'ingredientes'             => $listaOuVazia($receitaIA['ingredientes'] ?? null),
    'ingredientes_necessarios' => $listaOuVazia($receitaIA['ingredientes_necessarios'] ?? null),
    'modo_preparo'             => $listaOuVazia($receitaIA['modo_preparo'] ?? null),
    'dicas'                    => $listaOuVazia($receitaIA['dicas'] ?? null),
    'favorito'                 => false,
];

responder(true, 'Receita gerada com sucesso!', ['receita' => $receita]);
