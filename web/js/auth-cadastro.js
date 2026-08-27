// ── CADASTRO ──────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('formCadastro');
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    document.getElementById('erroGeral').textContent = '';
    document.getElementById('erroUsername').textContent = '';
    document.getElementById('erroEmail').textContent = '';
    document.getElementById('erroSenha').textContent = '';

    const username = document.getElementById('username').value.trim();
    const email = document.getElementById('email').value.trim();
    const senha = document.getElementById('senha').value.trim();

    const resp = await apiFetch('/usuarios/cadastro.php', {
      method: 'POST',
      body: { username, email, senha },
    });

    if (resp.sucesso) {
      window.location.href = 'login.html?sucesso=1';
      return;
    }

    if (resp.erros) {
      if (resp.erros.username) document.getElementById('erroUsername').textContent = resp.erros.username;
      if (resp.erros.email) document.getElementById('erroEmail').textContent = resp.erros.email;
      if (resp.erros.senha) document.getElementById('erroSenha').textContent = resp.erros.senha;
    } else {
      document.getElementById('erroGeral').textContent = resp.mensagem || 'Erro ao cadastrar.';
    }
  });
});
