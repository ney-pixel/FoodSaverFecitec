// ── HELPER DE COMUNICAÇÃO COM A API ──────────────────────────
// Todas as páginas do front-end usam esta função para conversar
// com a API PHP em ../../api/... via fetch(), sempre em JSON.

const API_BASE = '../../api';

/**
 * Faz uma requisição para a API e retorna o JSON já decodificado.
 * @param {string} caminho  Ex: '/estoque/listar_alimentos.php'
 * @param {object} opcoes   { method, body } — body é serializado como JSON automaticamente
 */
async function apiFetch(caminho, opcoes = {}) {
  const config = {
    method: opcoes.method || 'GET',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
  };
  if (opcoes.body !== undefined) {
    config.body = JSON.stringify(opcoes.body);
  }

  let resposta;
  try {
    resposta = await fetch(`${API_BASE}${caminho}`, config);
  } catch (e) {
    return { sucesso: false, mensagem: 'Não foi possível conectar ao servidor.' };
  }

  try {
    return await resposta.json();
  } catch (e) {
    return { sucesso: false, mensagem: 'Resposta inválida do servidor.' };
  }
}
