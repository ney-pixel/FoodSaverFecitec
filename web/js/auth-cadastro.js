// ── CADASTRO ──────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('formCadastro');
  const campoUsername = document.getElementById('username');
  const campoEmail = document.getElementById('email');
  const campoSenha = document.getElementById('senha');
  const campoConfirmarSenha = document.getElementById('confirmarSenha');
  const btn = document.getElementById('btnCadastrar');

  // Mesmo padrão aceito no servidor: letras (com acento), números, ponto, hífen, underscore
  const REGEX_USERNAME = /^[\p{L}\p{N}_.-]+$/u;

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

  // ── Validações (mesmas regras aplicadas no servidor) ──
  function validarUsername() {
    const valor = campoUsername.value.trim();
    if (!valor) return 'Informe um nome de usuário.';
    if (valor.length < 5 || valor.length > 30) return 'O nome de usuário deve ter entre 5 e 30 caracteres.';
    if (!REGEX_USERNAME.test(valor)) return 'Use apenas letras, números, ponto, hífen ou underscore (sem espaços).';
    return '';
  }
  function validarEmail() {
    const valor = campoEmail.value.trim();
    if (!valor) return 'Informe seu e-mail.';
    if (!campoEmail.checkValidity()) return 'Por favor, insira um e-mail válido.';
    return '';
  }
  function validarSenha() {
    const valor = campoSenha.value;
    if (!valor) return 'Crie uma senha.';
    if (valor.length < 6 || valor.length > 72) return 'A senha deve ter entre 6 e 72 caracteres.';
    if (!(/[A-Za-zÀ-ÿ]/.test(valor) && /\d/.test(valor))) return 'A senha deve conter letras e números.';
    const username = campoUsername.value.trim().toLowerCase();
    const email = campoEmail.value.trim().toLowerCase();
    if (valor.toLowerCase() === username || valor.toLowerCase() === email) {
      return 'A senha não pode ser igual ao usuário ou ao e-mail.';
    }
    return '';
  }
  function validarConfirmarSenha() {
    if (!campoConfirmarSenha.value) return 'Repita a senha para confirmar.';
    if (campoConfirmarSenha.value !== campoSenha.value) return 'As senhas não coincidem.';
    return '';
  }

  function mostrarErroCampo(campoInput, idErro, mensagem) {
    document.getElementById(idErro).textContent = mensagem;
    campoInput.closest('.campo').classList.toggle('invalido', !!mensagem);
  }

  // Validação ao sair do campo (blur)
  campoUsername.addEventListener('blur', () => mostrarErroCampo(campoUsername, 'erroUsername', validarUsername()));
  campoEmail.addEventListener('blur', () => mostrarErroCampo(campoEmail, 'erroEmail', validarEmail()));
  campoSenha.addEventListener('blur', () => mostrarErroCampo(campoSenha, 'erroSenha', validarSenha()));
  campoConfirmarSenha.addEventListener('blur', () => mostrarErroCampo(campoConfirmarSenha, 'erroConfirmarSenha', validarConfirmarSenha()));

  // Limpa o erro assim que o usuário começa a corrigir
  [
    [campoUsername, 'erroUsername'],
    [campoEmail, 'erroEmail'],
    [campoSenha, 'erroSenha'],
    [campoConfirmarSenha, 'erroConfirmarSenha'],
  ].forEach(([campo, idErro]) => {
    campo.addEventListener('input', () => {
      if (document.getElementById(idErro).textContent) mostrarErroCampo(campo, idErro, '');
    });
  });

  function definirCarregando(carregando) {
    btn.disabled = carregando;
    btn.innerHTML = carregando
      ? '<span class="spinner"></span><span class="btnTexto">Cadastrando...</span>'
      : '<span class="btnTexto">Cadastrar</span>';
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    document.getElementById('erroGeral').textContent = '';

    const erros = {
      erroUsername: validarUsername(),
      erroEmail: validarEmail(),
      erroSenha: validarSenha(),
      erroConfirmarSenha: validarConfirmarSenha(),
    };
    mostrarErroCampo(campoUsername, 'erroUsername', erros.erroUsername);
    mostrarErroCampo(campoEmail, 'erroEmail', erros.erroEmail);
    mostrarErroCampo(campoSenha, 'erroSenha', erros.erroSenha);
    mostrarErroCampo(campoConfirmarSenha, 'erroConfirmarSenha', erros.erroConfirmarSenha);

    const primeiroErro = Object.entries(erros).find(([, msg]) => msg);
    if (primeiroErro) {
      document.getElementById(primeiroErro[0]).closest('.campo').querySelector('input').focus();
      return;
    }

    const username = campoUsername.value.trim();
    const email = campoEmail.value.trim();
    const senha = campoSenha.value; // senha não é "trimada": espaços podem ser intencionais

    definirCarregando(true);
    const resp = await apiFetch('/usuarios/cadastro.php', {
      method: 'POST',
      body: { username, email, senha },
    });
    definirCarregando(false);

    if (resp.sucesso) {
      window.location.href = 'login.html?sucesso=1';
      return;
    }

    if (resp.erros) {
      if (resp.erros.username) mostrarErroCampo(campoUsername, 'erroUsername', resp.erros.username);
      if (resp.erros.email) mostrarErroCampo(campoEmail, 'erroEmail', resp.erros.email);
      if (resp.erros.senha) mostrarErroCampo(campoSenha, 'erroSenha', resp.erros.senha);
    } else {
      document.getElementById('erroGeral').textContent = resp.mensagem || 'Não foi possível concluir o cadastro. Tente novamente.';
    }
  });
});
