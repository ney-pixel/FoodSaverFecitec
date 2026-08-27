// ── LOGIN ─────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  // Mensagens vindas por querystring (equivalente ao antigo ?sucesso=1 / ?desativada=1)
  const params = new URLSearchParams(window.location.search);
  const msgEl = document.getElementById('msgSucesso');
  if (params.get('sucesso') === '1') {
    msgEl.textContent = 'Cadastro realizado com sucesso! Faça seu login.';
    msgEl.style.display = 'block';
  } else if (params.get('desativada') === '1') {
    msgEl.textContent = 'Sua conta foi desativada. Faça login novamente a qualquer momento para reativá-la.';
    msgEl.style.display = 'block';
  }

  const form = document.getElementById('formLogin');
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    document.getElementById('erroEmail').textContent = '';
    document.getElementById('erroSenha').textContent = '';

    const email = document.getElementById('email').value.trim();
    const senha = document.getElementById('senha').value.trim();

    const resp = await apiFetch('/usuarios/login.php', {
      method: 'POST',
      body: { email, senha },
    });

    if (resp.sucesso) {
      window.location.href = 'perfil.html';
      return;
    }

    if (resp.erros) {
      if (resp.erros.email) document.getElementById('erroEmail').textContent = resp.erros.email;
      if (resp.erros.senha) document.getElementById('erroSenha').textContent = resp.erros.senha;
    } else {
      document.getElementById('erroSenha').textContent = resp.mensagem || 'Erro ao fazer login.';
    }
  });
});
