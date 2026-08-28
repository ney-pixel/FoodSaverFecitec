// ── LOGIN ─────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  // Mensagens vindas por querystring (equivalente ao antigo ?sucesso=1 / ?desativada=1)
  const params = new URLSearchParams(window.location.search);
  const msgEl = document.getElementById('msgSucesso');
  if (params.get('sucesso') === '1') {
    msgEl.textContent = 'Cadastro realizado com sucesso! Faça seu login.';
    msgEl.style.display = 'flex';
  } else if (params.get('desativada') === '1') {
    msgEl.textContent = 'Sua conta foi desativada. Faça login novamente a qualquer momento para reativá-la.';
    msgEl.style.display = 'flex';
  }

  const form = document.getElementById('formLogin');
  const campoEmail = document.getElementById('email');
  const campoSenha = document.getElementById('senha');
  const btn = document.getElementById('btnEntrar');

  // ── Mostrar/ocultar senha ──
  document.querySelectorAll('.toggleSenha').forEach((toggle) => {
    toggle.addEventListener('click', () => {
      const alvo = document.getElementById(toggle.dataset.alvo);
      const icone = toggle.querySelector('i');
      const mostrando = alvo.type === 'text';
      alvo.type = mostrando ? 'password' : 'text';
      icone.classList.toggle('bi-eye', mostrando);
      icone.classList.toggle('bi-eye-slash', !mostrando);
    });
  });

  function validarEmail() {
    const valor = campoEmail.value.trim();
    if (!valor) return 'Informe seu e-mail.';
    if (!campoEmail.checkValidity()) return 'Por favor, insira um e-mail válido.';
    return '';
  }
  function validarSenha() {
    if (!campoSenha.value) return 'Informe sua senha.';
    return '';
  }

  function mostrarErroCampo(campoInput, idErro, mensagem) {
    document.getElementById(idErro).textContent = mensagem;
    campoInput.closest('.campo').classList.toggle('invalido', !!mensagem);
  }

  campoEmail.addEventListener('blur', () => mostrarErroCampo(campoEmail, 'erroEmail', validarEmail()));
  campoSenha.addEventListener('blur', () => mostrarErroCampo(campoSenha, 'erroSenha', validarSenha()));
  [
    [campoEmail, 'erroEmail'],
    [campoSenha, 'erroSenha'],
  ].forEach(([campo, idErro]) => {
    campo.addEventListener('input', () => {
      if (document.getElementById(idErro).textContent) mostrarErroCampo(campo, idErro, '');
    });
  });

  function definirCarregando(carregando) {
    btn.disabled = carregando;
    btn.innerHTML = carregando
      ? '<span class="spinner"></span><span class="btnTexto">Entrando...</span>'
      : '<span class="btnTexto">Entrar</span>';
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    document.getElementById('erroGeral').textContent = '';

    const erroEmail = validarEmail();
    const erroSenha = validarSenha();
    mostrarErroCampo(campoEmail, 'erroEmail', erroEmail);
    mostrarErroCampo(campoSenha, 'erroSenha', erroSenha);
    if (erroEmail || erroSenha) {
      (erroEmail ? campoEmail : campoSenha).focus();
      return;
    }

    const email = campoEmail.value.trim();
    const senha = campoSenha.value; // senha não é "trimada": espaços podem ser intencionais

    definirCarregando(true);
    const resp = await apiFetch('/usuarios/login.php', {
      method: 'POST',
      body: { email, senha },
    });
    definirCarregando(false);

    if (resp.sucesso) {
      window.location.href = 'perfil.html';
      return;
    }

    if (resp.erros) {
      if (resp.erros.email) mostrarErroCampo(campoEmail, 'erroEmail', resp.erros.email);
      if (resp.erros.senha) mostrarErroCampo(campoSenha, 'erroSenha', resp.erros.senha);
    } else {
      document.getElementById('erroGeral').textContent = resp.mensagem || 'Não foi possível entrar. Tente novamente.';
    }
  });
});
