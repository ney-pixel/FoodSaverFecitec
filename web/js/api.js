// Helper de comunicação com a API (fetch em JSON)

const API_BASE = '../../api';

/**
 * @param {string} caminho  Ex: '/estoque/listar_alimentos.php'
 * @param {object} opcoes   { method, body }
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
