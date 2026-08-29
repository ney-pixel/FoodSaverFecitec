// ══════════════════════════════════════════════════════════════
// FoodSaver — Perfil (SPA client-side)
// Toda a lógica de acesso ao banco foi movida para ../../api/.
// Este arquivo só busca dados via fetch() e desenha a interface,
// preservando o layout/CSS original de perfil.php.
// ══════════════════════════════════════════════════════════════

const ESTADO = {
  usuario: null,
  alimentos: [],
  biblioteca: [],
  receitasIA: [],
  compras: [],
  gruposAlimentos: [],
  config: null,
  movimentacoes: null,
};

// Receitas favoritadas: as da biblioteca (catálogo fixo, favorito é uma
// coluna na própria receita) e as geradas por IA que o usuário salvou
// (só existem no banco a partir do momento que são favoritadas).
function receitasFavoritas() {
  return [...ESTADO.biblioteca.filter((r) => r.favorito), ...ESTADO.receitasIA];
}

// ── HELPERS DE DOMÍNIO (equivalentes às funções PHP originais) ──
function diasValidade(validade) {
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const val = new Date(validade + 'T00:00:00');
  return Math.round((val - hoje) / 86400000);
}
function classeValidade(dias) {
  if (dias < 0) return 'danger';
  if (dias <= 2) return 'warning';
  return 'good';
}
function textoValidade(dias) {
  if (dias < 0) return `Vencido há ${Math.abs(dias)} dia(s)`;
  return `Vence em ${dias} dia(s)`;
}
function qtdFormatada(valor, unidade) {
  const v = parseFloat(valor);
  const texto = (v === Math.floor(v)) ? String(Math.trunc(v)) : v.toFixed(2).replace(/0+$/, '').replace(/\.$/, '');
  return `${texto} ${unidade}`;
}
function iniciaisNome(nome) {
  const partes = (nome || '').trim().split(' ');
  return (partes[0]?.[0] || '') .concat(partes[1]?.[0] || '').toUpperCase();
}
function esc(txt) {
  const d = document.createElement('div');
  d.textContent = txt ?? '';
  return d.innerHTML;
}
function msgFeedback(containerId, tipo, texto) {
  const icon = tipo === 'ok' ? 'bi-check-circle-fill' : 'bi-exclamation-circle-fill';
  document.getElementById(containerId).innerHTML =
    `<div class="msg-feedback msg-${tipo}"><i class="bi ${icon}"></i> ${esc(texto)}</div>`;
}
function limparMsg(containerId) {
  document.getElementById(containerId).innerHTML = '';
}

// ── CARREGAMENTO DE DADOS ────────────────────────────────────
async function carregarTudo() {
  const [alimentosResp, bibliotecaResp, receitasIAResp, comprasResp, configResp, gAlResp, movResp] = await Promise.all([
    apiFetch('/estoque/listar_alimentos.php'),
    apiFetch('/biblioteca/listar_biblioteca.php'),
    apiFetch('/ia/listar_receitas_ia.php'),
    apiFetch('/compras/listar_compras.php'),
    apiFetch('/configuracoes/listar_configuracoes.php'),
    apiFetch('/grupos/gerenciar_grupo_alimentos.php'),
    apiFetch('/estoque/listar_movimentacoes.php'),
  ]);
  ESTADO.alimentos = alimentosResp.alimentos || [];
  ESTADO.biblioteca = bibliotecaResp.receitas || [];
  ESTADO.receitasIA = receitasIAResp.receitas || [];
  ESTADO.compras = comprasResp.lista_compras || [];
  ESTADO.config = configResp.configuracoes || null;
  ESTADO.gruposAlimentos = gAlResp.grupos || [];
  ESTADO.movimentacoes = movResp.sucesso ? movResp : null;
}

function renderTudo() {
  renderSidebar();
  renderInventario();
  renderReceitas();
  renderIngredientesSelecionadosCriar();
  renderCompras();
  renderGruposAlimentos();
  renderRelatorios();
  renderConfig();
}

// ── SIDEBAR ───────────────────────────────────────────────────
function renderSidebar() {
  const qtdFavoritas = receitasFavoritas().length;
  const nivel = Math.floor(qtdFavoritas / 2) + 1;
  const plano = (ESTADO.config?.plano || 'gratuito') === 'premium' ? 'Premium' : 'Free';
  const nome = ESTADO.usuario?.username || '';

  document.getElementById('sbAvatar').textContent = iniciaisNome(nome);
  document.getElementById('sbNivel').textContent = nivel;
  document.getElementById('sbNome').textContent = nome;
  document.getElementById('sbPlano').textContent = `Plano ${plano}`;
}

// ── NAVEGAÇÃO ENTRE SEÇÕES ───────────────────────────────────
const SECOES = ['inventario', 'receitas', 'compras', 'grupos', 'planos', 'relatorios', 'config'];
function mostrarSecao(sec) {
  if (!SECOES.includes(sec)) sec = 'inventario';
  SECOES.forEach((s) => document.getElementById(s).classList.toggle('hidden', s !== sec));
  document.querySelectorAll('.nav-item').forEach((el) => el.classList.toggle('active', el.dataset.sec === sec));
  history.replaceState(null, '', `#${sec}`);
  if (window.innerWidth <= 900) toggleSidebar(true);
}
function bindNav() {
  document.querySelectorAll('.nav-item').forEach((el) => {
    el.addEventListener('click', (e) => {
      e.preventDefault();
      mostrarSecao(el.dataset.sec);
    });
  });
}

// ── MODAL DE CONFIRMAÇÃO (substitui o confirm() nativo do navegador) ──
let _confirmResolve = null;
function abrirConfirm(texto, opts = {}) {
  document.getElementById('confirmTitulo').textContent = opts.titulo || 'Tem certeza?';
  document.getElementById('confirmTexto').textContent = texto;
  document.getElementById('confirmBtnOk').innerHTML = `<i class="bi ${opts.icone || 'bi-trash3-fill'}"></i> ${opts.botao || 'Excluir'}`;
  document.getElementById('modalConfirm').classList.remove('hidden');
  document.body.style.overflow = 'hidden';
  return new Promise((resolve) => { _confirmResolve = resolve; });
}
function fecharConfirm(resultado) {
  document.getElementById('modalConfirm').classList.add('hidden');
  document.body.style.overflow = '';
  if (_confirmResolve) {
    const resolve = _confirmResolve;
    _confirmResolve = null;
    resolve(resultado);
  }
}

// ══════════════════════════════════════════════════════════════
// INVENTÁRIO
// ══════════════════════════════════════════════════════════════
function renderInventario() {
  const grid = document.getElementById('inventoryGrid');
  const vazio = ESTADO.alimentos.length === 0;
  document.getElementById('invEmpty').style.display = vazio ? '' : 'none';
  document.getElementById('invSearchBar').style.display = vazio ? 'none' : '';
  document.getElementById('invSub').textContent =
    `Seus alimentos em estoque (${ESTADO.alimentos.length} ${ESTADO.alimentos.length === 1 ? 'item' : 'itens'})`;

  grid.innerHTML = ESTADO.alimentos.map((it) => {
    const dias = diasValidade(it.validade);
    const classe = classeValidade(dias);
    const texto = textoValidade(dias);
    return `
    <div class="inv-card" data-name="${esc(it.nome.toLowerCase())}">
      <div class="inv-info">
        <span class="inv-name">${esc(it.nome)}</span>
        <span class="inv-qty">${esc(it.quantidade)} ${esc(it.unidade)}</span>
        <div class="inv-expiry ${classe}"><i class="bi bi-clock"></i> ${texto}</div>
      </div>
      <div class="inv-actions">
        <button type="button" class="inv-btn use" title="Registrar consumo/descarte" onclick="abrirModalMov(${it.id})"><i class="bi bi-arrow-down-circle-fill"></i></button>
        <button type="button" class="inv-btn edit" title="Editar" onclick="abrirModalEdit(${it.id})"><i class="bi bi-pencil-fill"></i></button>
        <button type="button" class="inv-btn delete" title="Excluir" onclick="excluirAlimento(${it.id})"><i class="bi bi-trash3-fill"></i></button>
      </div>
      <div class="inv-status-bar ${classe}"></div>
    </div>`;
  }).join('');
}

function abrirModalAdd() {
  document.getElementById('modalInvTitulo').textContent = 'Adicionar Alimento';
  document.getElementById('invSubmitBtn').innerHTML = '<i class="bi bi-check2"></i> Adicionar';
  document.getElementById('invId').value = '0';
  document.getElementById('invNome').value = '';
  document.getElementById('invQuantidade').value = '';
  document.getElementById('invUnidade').value = 'kg';
  document.getElementById('invValidade').value = '';
  document.getElementById('invQtdMinima').value = '';
  document.getElementById('modalInv').classList.remove('hidden');
  document.body.style.overflow = 'hidden';
}
function abrirModalEdit(id) {
  const it = ESTADO.alimentos.find((a) => a.id === id);
  if (!it) return;
  document.getElementById('modalInvTitulo').textContent = 'Editar Alimento';
  document.getElementById('invSubmitBtn').innerHTML = '<i class="bi bi-check2"></i> Salvar Alterações';
  document.getElementById('invId').value = it.id;
  document.getElementById('invNome').value = it.nome;
  document.getElementById('invQuantidade').value = it.quantidade;
  document.getElementById('invUnidade').value = it.unidade;
  document.getElementById('invValidade').value = it.validade;
  document.getElementById('invQtdMinima').value = it.quantidade_minima ?? '';
  document.getElementById('modalInv').classList.remove('hidden');
  document.body.style.overflow = 'hidden';
}
function fecharModalInv() {
  document.getElementById('modalInv').classList.add('hidden');
  document.body.style.overflow = '';
}

async function submitFormInv(e) {
  e.preventDefault();
  const id = parseInt(document.getElementById('invId').value, 10);
  const payload = {
    nome: document.getElementById('invNome').value.trim(),
    quantidade: document.getElementById('invQuantidade').value.trim(),
    unidade: document.getElementById('invUnidade').value,
    validade: document.getElementById('invValidade').value,
    quantidade_minima: document.getElementById('invQtdMinima').value.trim(),
  };
  let resp;
  if (id > 0) {
    payload.id = id;
    resp = await apiFetch('/estoque/editar_alimento.php', { method: 'PUT', body: payload });
  } else {
    resp = await apiFetch('/estoque/cadastrar_alimento.php', { method: 'POST', body: payload });
  }
  if (resp.sucesso) {
    fecharModalInv();
    await carregarTudo();
    renderInventario();
    renderRelatorios();
    renderConfig();
    renderGruposAlimentos();
    renderCompras();
    msgFeedback('invMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('invMsg', 'erro', resp.mensagem || 'Erro ao salvar item.');
  }
}

async function excluirAlimento(id) {
  if (!(await abrirConfirm('Remover este item do seu inventário?', { titulo: 'Remover alimento' }))) return;
  const resp = await apiFetch('/estoque/excluir_alimento.php', { method: 'DELETE', body: { id } });
  if (resp.sucesso) {
    await carregarTudo();
    renderInventario();
    renderRelatorios();
    renderConfig();
    renderGruposAlimentos();
    renderCompras();
  } else {
    msgFeedback('invMsg', 'erro', resp.mensagem || 'Erro ao excluir item.');
  }
}

function filtrarInventario(query) {
  const q = query.toLowerCase().trim();
  document.querySelectorAll('#inventoryGrid .inv-card').forEach((card) => {
    const nome = card.dataset.name || '';
    card.style.display = nome.includes(q) ? '' : 'none';
  });
}

// ── MOVIMENTAÇÃO (consumo/desperdício) ───────────────────────
function abrirModalMov(id) {
  const it = ESTADO.alimentos.find((a) => a.id === id);
  if (!it) return;
  document.getElementById('movAlimentoId').value = it.id;
  document.getElementById('movNomeAlimento').textContent = it.nome;
  document.getElementById('movDisponivel').textContent = qtdFormatada(it.quantidade, it.unidade);
  document.getElementById('movQuantidade').value = '';
  document.getElementById('movUnidade').value = it.unidade;
  selecionarTipoMov('consumo');
  document.getElementById('modalMov').classList.remove('hidden');
  document.body.style.overflow = 'hidden';
}
function fecharModalMov() {
  document.getElementById('modalMov').classList.add('hidden');
  document.body.style.overflow = '';
}
function selecionarTipoMov(tipo) {
  document.getElementById('movTipo').value = tipo;
  document.querySelectorAll('.mov-tipo-btn').forEach((b) => b.classList.toggle('active', b.dataset.tipo === tipo));
}

async function submitFormMov(e) {
  e.preventDefault();
  const alimentoId = parseInt(document.getElementById('movAlimentoId').value, 10);
  const tipo = document.getElementById('movTipo').value;
  const quantidade = document.getElementById('movQuantidade').value.trim();
  const unidade_medida = document.getElementById('movUnidade').value;
  const resp = await apiFetch('/estoque/movimentar_alimento.php', {
    method: 'POST',
    body: { alimento_id: alimentoId, tipo, quantidade, unidade_medida },
  });
  if (resp.sucesso) {
    fecharModalMov();
    await carregarTudo();
    renderInventario();
    renderRelatorios();
    renderConfig();
    renderGruposAlimentos();
    renderCompras();
    msgFeedback('invMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('invMsg', 'erro', resp.mensagem || 'Erro ao registrar movimentação.');
  }
}

// ══════════════════════════════════════════════════════════════
// RECEITAS
// Três subabas, iguais ao app mobile (menos "Grupos", que não existe
// no web): Criar, Favoritas e Biblioteca. Não é mais o usuário que
// cadastra receita — a biblioteca é um catálogo fixo, mantido por nós.
// ══════════════════════════════════════════════════════════════
function dificuldadeClasse(d) {
  if (d === 'Fácil') return 'good';
  if (d === 'Médio') return 'warning';
  return 'danger';
}

function mudarTabReceita(tab) {
  document.querySelectorAll('.rtab-btn[data-rtab]').forEach((b) => b.classList.toggle('active', b.dataset.rtab === tab));
  document.getElementById('tabReceitaCriar').classList.toggle('hidden', tab !== 'criar');
  document.getElementById('tabReceitaFavoritas').classList.toggle('hidden', tab !== 'favoritas');
  document.getElementById('tabReceitaBiblioteca').classList.toggle('hidden', tab !== 'biblioteca');
}

function renderReceitas() {
  renderFavoritas();
  renderBiblioteca();
}

// ── SUBABA: CRIAR (geração por IA a partir do estoque) ──
const NOMES_FOME = ['Leve', 'Médio', 'Muita fome'];
const criarReceitaState = { ingredientes: [], porcoes: 2, fome: 0 };
let _sugestoesCriarAtual = [];

function renderSugestoesCriar() {
  const busca = document.getElementById('criarBuscaIngrediente').value.trim().toLowerCase();
  const wrap = document.getElementById('criarSugestoes');
  if (!busca) {
    wrap.classList.add('hidden');
    wrap.innerHTML = '';
    _sugestoesCriarAtual = [];
    return;
  }
  _sugestoesCriarAtual = ESTADO.alimentos
    .map((a) => a.nome)
    .filter((nome) => nome.toLowerCase().includes(busca) && !criarReceitaState.ingredientes.includes(nome));

  wrap.classList.remove('hidden');
  wrap.innerHTML = _sugestoesCriarAtual.length === 0
    ? `<div class="ing-suggestion-empty"><i class="bi bi-info-circle"></i> Nenhum alimento com esse nome no seu estoque.</div>`
    : _sugestoesCriarAtual.map((nome, i) => `
        <button type="button" class="ing-suggestion-item" onclick="selecionarIngredienteCriarPorIndice(${i})">
          <i class="bi bi-plus-circle"></i> ${esc(nome)}
        </button>`).join('');
}

function fecharSugestoesCriarSeFora(e) {
  const wrap = document.getElementById('criarSugestoes');
  const input = document.getElementById('criarBuscaIngrediente');
  if (!wrap || !input || wrap.classList.contains('hidden')) return;
  if (e.target === input || wrap.contains(e.target)) return;
  wrap.classList.add('hidden');
}

function selecionarIngredienteCriarPorIndice(i) {
  const nome = _sugestoesCriarAtual[i];
  if (!nome) return;
  if (!criarReceitaState.ingredientes.includes(nome)) criarReceitaState.ingredientes.push(nome);
  document.getElementById('criarBuscaIngrediente').value = '';
  document.getElementById('criarSugestoes').classList.add('hidden');
  document.getElementById('criarSugestoes').innerHTML = '';
  renderIngredientesSelecionadosCriar();
}

function removerIngredienteCriarPorIndice(i) {
  criarReceitaState.ingredientes.splice(i, 1);
  renderIngredientesSelecionadosCriar();
}

// Mini cards com todo o estoque, pra selecionar sem precisar digitar nada.
function selecionarIngredienteCriarPorAlimentoId(id) {
  const alimento = ESTADO.alimentos.find((a) => a.id === id);
  if (!alimento) return;
  if (!criarReceitaState.ingredientes.includes(alimento.nome)) criarReceitaState.ingredientes.push(alimento.nome);
  renderIngredientesSelecionadosCriar();
}

function renderIngredientesDisponiveisCriar() {
  const wrap = document.getElementById('criarIngredientesDisponiveis');
  const disponiveis = ESTADO.alimentos.filter((a) => !criarReceitaState.ingredientes.includes(a.nome));

  if (disponiveis.length === 0) {
    wrap.innerHTML = `<p class="ing-mini-empty"><i class="bi bi-info-circle"></i> ${
      ESTADO.alimentos.length === 0
        ? 'Adicione itens ao inventário para vê-los aqui.'
        : 'Todos os itens do estoque já foram selecionados.'
    }</p>`;
    return;
  }

  wrap.innerHTML = disponiveis.map((a) => {
    const dias = diasValidade(a.validade);
    const classe = classeValidade(dias);
    return `
      <button type="button" class="ing-mini-card" onclick="selecionarIngredienteCriarPorAlimentoId(${a.id})">
        <span class="ing-mini-card-icon"><i class="bi bi-egg-fried"></i></span>
        <span class="ing-mini-card-nome">${esc(a.nome)}</span>
        <span class="expiry-pill ${classe}">${Math.abs(dias)}d</span>
      </button>`;
  }).join('');
}

function renderIngredientesSelecionadosCriar() {
  const total = criarReceitaState.ingredientes.length;
  document.getElementById('criarIngCounter').textContent = `${total} selecionado${total === 1 ? '' : 's'}`;
  document.getElementById('criarIngSelecionados').innerHTML = total === 0
    ? '<p class="campo-hint" style="margin:0">Nenhum ingrediente selecionado ainda.</p>'
    : criarReceitaState.ingredientes.map((nome, i) => `
        <span class="ing-chip-sel">${esc(nome)} <button type="button" onclick="removerIngredienteCriarPorIndice(${i})" title="Remover"><i class="bi bi-x-lg"></i></button></span>
      `).join('');

  const btn = document.getElementById('btnGerarReceita');
  btn.disabled = total === 0;
  btn.innerHTML = total === 0
    ? 'Selecione ingredientes acima'
    : `<i class="bi bi-stars"></i> Gerar receita com ${total} ingrediente${total === 1 ? '' : 's'}`;

  renderIngredientesDisponiveisCriar();
}

function alterarPorcoesCriar(delta) {
  criarReceitaState.porcoes = Math.max(1, criarReceitaState.porcoes + delta);
  document.getElementById('criarPorcoesVal').textContent = criarReceitaState.porcoes;
}

function selecionarFomeCriar(indice) {
  criarReceitaState.fome = indice;
  document.querySelectorAll('#criarFomeToggle .fome-btn').forEach((b) => b.classList.toggle('active', Number(b.dataset.fome) === indice));
}

// Chama a IA (Gemini, via api/ia/gerar_receita.php) com os ingredientes
// selecionados do estoque, porções, nível de fome e observações — mesmo
// endpoint usado pelo app mobile (lib/receitas.dart).
async function gerarReceita() {
  if (criarReceitaState.ingredientes.length === 0) return;

  const btn = document.getElementById('btnGerarReceita');
  const textoOriginal = btn.innerHTML;
  btn.disabled = true;
  btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Gerando receita...';
  limparMsg('recMsg');

  const resp = await apiFetch('/ia/gerar_receita.php', {
    method: 'POST',
    body: {
      ingredientes: criarReceitaState.ingredientes,
      porcoes: criarReceitaState.porcoes,
      nivel_fome: NOMES_FOME[criarReceitaState.fome],
      observacoes: (document.getElementById('criarObservacoes')?.value || '').trim(),
    },
  });

  btn.disabled = criarReceitaState.ingredientes.length === 0;
  btn.innerHTML = textoOriginal;

  if (!resp.sucesso) {
    msgFeedback('recMsg', 'erro', resp.mensagem || 'Não foi possível gerar a receita agora. Tente novamente.');
    return;
  }

  exibirReceitaNoModal(resp.receita);
}

// ── SUBABA: FAVORITAS ────────────────────────────────────────────
// Usa índice (não id) nos onclick porque biblioteca e receitas de IA têm
// contadores de id independentes — o mesmo id pode existir nas duas.
let _favoritasAtuais = [];

function renderFavoritas() {
  const favoritas = receitasFavoritas();
  _favoritasAtuais = favoritas;
  document.getElementById('favEmpty').style.display = favoritas.length === 0 ? '' : 'none';
  document.getElementById('favoritasGrid').innerHTML = favoritas.map((r, i) => `
    <div class="receita-card-saved is-fav">
      <div class="rc-head">
        <div>
          <div class="rc-titulo">${esc(r.titulo)} ${r.gerada_por_ia ? '<span class="rtag ia-tag" style="margin-left:6px"><i class="bi bi-stars"></i> IA</span>' : ''}</div>
          <div class="rc-meta" style="margin-top:6px">
            <span class="rc-tag"><i class="bi bi-timer"></i> ${r.tempo_preparo} min</span>
            <span class="rc-tag"><i class="bi bi-people-fill"></i> ${r.porcoes} ${r.porcoes === 1 ? 'porção' : 'porções'}</span>
          </div>
        </div>
        <button type="button" class="rc-fav active" title="Remover dos favoritos" onclick="desfavoritarFavoritaPorIndice(${i})">
          <i class="bi bi-star-fill"></i>
        </button>
      </div>
      ${r.ingredientes_necessarios?.length ? `<div class="rc-ings">${r.ingredientes_necessarios.map((i) => `<span class="rc-ing"><i class="bi bi-check2"></i> ${esc(i)}</span>`).join('')}</div>` : ''}
      <button type="button" class="btn-ghost" style="width:100%;justify-content:center" onclick="verFavoritaPorIndice(${i})"><i class="bi bi-eye"></i> Ver receita</button>
    </div>
  `).join('');
}

function verFavoritaPorIndice(i) {
  const r = _favoritasAtuais[i];
  if (r) exibirReceitaNoModal(r);
}

async function desfavoritarFavoritaPorIndice(i) {
  const r = _favoritasAtuais[i];
  if (!r) return;
  if (r.gerada_por_ia) {
    await favoritarReceitaIA(r);
  } else {
    await favoritarReceita(r.id);
  }
}

// ── SUBABA: BIBLIOTECA ───────────────────────────────────────────
function renderBiblioteca() {
  const busca = (document.getElementById('bibBusca')?.value || '').trim().toLowerCase();
  const filtradas = busca
    ? ESTADO.biblioteca.filter((r) => r.titulo.toLowerCase().includes(busca) || r.categoria.toLowerCase().includes(busca))
    : ESTADO.biblioteca;

  document.getElementById('bibEmpty').style.display = filtradas.length === 0 ? '' : 'none';
  document.getElementById('bibliotecaGrid').innerHTML = filtradas.map((r) => `
    <div class="receita-card" onclick="abrirModalReceita(${r.id})">
      <div class="receita-banner">
        <i class="bi bi-journal-richtext"></i>
        ${r.favorito ? '<i class="bi bi-star-fill receita-banner-fav"></i>' : ''}
      </div>
      <div class="receita-body">
        <div class="receita-tags">
          <span class="rtag green-tag">${esc(r.categoria)}</span>
          <span class="expiry-pill ${dificuldadeClasse(r.dificuldade)}">${esc(r.dificuldade)}</span>
        </div>
        <h3>${esc(r.titulo)}</h3>
        <p>${esc(r.descricao || '')}</p>
        <div class="receita-ingredients">
          ${(r.ingredientes_necessarios || []).slice(0, 4).map((i) => `<span>${esc(i)}</span>`).join('')}
        </div>
        <div class="receita-footer">
          <span class="receita-footer-item"><i class="bi bi-timer"></i> ${r.tempo_preparo} min</span>
          <span class="receita-footer-item"><i class="bi bi-people"></i> ${r.porcoes}x</span>
          <span class="receita-footer-item receita-footer-cal"><i class="bi bi-fire"></i> ${r.calorias} kcal</span>
        </div>
      </div>
    </div>
  `).join('');
}

// ── MODAL DE DETALHE (compartilhado entre as 3 subabas) ─────────
// _receitaModalId: id na biblioteca (quando a receita mostrada é de lá).
// _receitaModalIA: o objeto inteiro (quando a receita mostrada veio da IA
// — antes de favoritada ela não tem id nenhuma tabela, então guardamos o
// objeto todo pra poder favoritar depois).
let _receitaModalId = null;
let _receitaModalIA = null;

function abrirModalReceita(id) {
  const r = ESTADO.biblioteca.find((x) => x.id === id);
  if (!r) return;
  exibirReceitaNoModal(r);
}

function exibirReceitaNoModal(r) {
  _receitaModalId = r.gerada_por_ia ? null : r.id;
  _receitaModalIA = r.gerada_por_ia ? r : null;

  document.getElementById('mrTitulo').textContent = r.titulo;
  document.getElementById('mrDescricao').textContent = r.descricao || '';
  document.getElementById('mrTags').innerHTML = `
    ${r.gerada_por_ia ? '<span class="rtag ia-tag"><i class="bi bi-stars"></i> Gerada por IA</span>' : ''}
    <span class="rtag green-tag">${esc(r.categoria)}</span>
    <span class="expiry-pill ${dificuldadeClasse(r.dificuldade)}">${esc(r.dificuldade)}</span>
    <span class="rc-tag"><i class="bi bi-timer"></i> ${r.tempo_preparo} min</span>
    <span class="rc-tag"><i class="bi bi-people-fill"></i> ${r.porcoes} porções</span>
    <span class="rc-tag"><i class="bi bi-fire"></i> ${r.calorias} kcal</span>
  `;
  document.getElementById('mrIngredientes').innerHTML = (r.ingredientes || []).map((i) => `<li>${esc(i)}</li>`).join('');
  document.getElementById('mrPreparo').innerHTML = (r.modo_preparo || []).map((p) => `<li>${esc(p)}</li>`).join('');

  const dicasWrap = document.getElementById('mrDicasWrap');
  if (r.dicas?.length) {
    dicasWrap.classList.remove('hidden');
    document.getElementById('mrDicas').innerHTML = r.dicas.map((d) => `<p><i class="bi bi-lightbulb-fill"></i> ${esc(d)}</p>`).join('');
  } else {
    dicasWrap.classList.add('hidden');
  }

  atualizarBotaoFavoritoModal(r.favorito);
  document.getElementById('modalReceita').classList.remove('hidden');
  document.body.style.overflow = 'hidden';
}

function atualizarBotaoFavoritoModal(favorito) {
  const btn = document.getElementById('mrFavBtn');
  btn.classList.toggle('active', favorito);
  btn.innerHTML = favorito ? '<i class="bi bi-star-fill"></i> Favoritada' : '<i class="bi bi-star"></i> Favoritar';
}

function fecharModalReceita() {
  document.getElementById('modalReceita').classList.add('hidden');
  document.body.style.overflow = '';
  _receitaModalId = null;
  _receitaModalIA = null;
}

async function alternarFavoritoModal() {
  if (_receitaModalIA) {
    await favoritarReceitaIA(_receitaModalIA);
    atualizarBotaoFavoritoModal(_receitaModalIA.favorito);
    return;
  }
  if (_receitaModalId === null) return;
  await favoritarReceita(_receitaModalId);
  const r = ESTADO.biblioteca.find((x) => x.id === _receitaModalId);
  if (r) atualizarBotaoFavoritoModal(r.favorito);
}

async function favoritarReceita(id) {
  const resp = await apiFetch('/biblioteca/favoritar_biblioteca.php', { method: 'POST', body: { id } });
  if (resp.sucesso) {
    const rec = ESTADO.biblioteca.find((r) => r.id === id);
    if (rec) rec.favorito = resp.favorito;
    renderReceitas();
    renderSidebar();
    renderConfig();
    renderRelatorios();
  }
}

// Favorita/desfavorita uma receita gerada por IA (api/ia/favoritar_receita_ia.php):
//   - ainda sem id (nunca favoritada) -> manda a receita inteira, o servidor insere e devolve o id.
//   - já com id (estava favoritada)   -> manda só o id, o servidor apaga (desfavoritar).
async function favoritarReceitaIA(receita) {
  const corpo = receita.id > 0
    ? { id: receita.id }
    : {
        titulo: receita.titulo,
        descricao: receita.descricao,
        categoria: receita.categoria,
        dificuldade: receita.dificuldade,
        tempo_preparo: receita.tempo_preparo,
        porcoes: receita.porcoes,
        calorias: receita.calorias,
        ingredientes: receita.ingredientes,
        ingredientes_necessarios: receita.ingredientes_necessarios,
        modo_preparo: receita.modo_preparo,
        dicas: receita.dicas,
      };

  const resp = await apiFetch('/ia/favoritar_receita_ia.php', { method: 'POST', body: corpo });
  if (!resp.sucesso) return;

  receita.id = resp.id;
  receita.favorito = resp.favorito;
  receita.gerada_por_ia = true;

  if (resp.favorito) {
    if (!ESTADO.receitasIA.some((r) => r.id === receita.id)) {
      ESTADO.receitasIA = [{ ...receita }, ...ESTADO.receitasIA];
    }
  } else {
    ESTADO.receitasIA = ESTADO.receitasIA.filter((r) => r.id !== receita.id);
  }

  renderReceitas();
  renderSidebar();
}

// ══════════════════════════════════════════════════════════════
// LISTA DE COMPRAS
// ══════════════════════════════════════════════════════════════
function renderCompras() {
  document.getElementById('compraEmpty').style.display = ESTADO.compras.length === 0 ? '' : 'none';
  document.getElementById('comprasList').innerHTML = ESTADO.compras.map((item) => `
    <div class="compra-item ${item.comprado ? 'comprado' : ''}">
      <button type="button" class="compra-check" title="Marcar como comprado" onclick="toggleCompra(${item.id})">
        <i class="bi ${item.comprado ? 'bi-check-circle-fill' : 'bi-circle'}"></i>
      </button>
      <div class="compra-info">
        <span class="compra-nome">${esc(item.nome_alimento)}</span>
        <span class="compra-qtd">${esc(qtdFormatada(item.quantidade, item.unidade_medida))}</span>
      </div>
      ${item.automatico ? '<span class="compra-auto-tag" title="Adicionado automaticamente"><i class="bi bi-magic"></i> Auto</span>' : ''}
      <button type="button" class="inv-btn delete" title="Remover" onclick="removerCompra(${item.id})"><i class="bi bi-trash3-fill"></i></button>
    </div>
  `).join('');
}

function abrirModalCompra() {
  document.getElementById('formCompra').reset();
  document.getElementById('modalCompra').classList.remove('hidden');
  document.body.style.overflow = 'hidden';
}
function fecharModalCompra() {
  document.getElementById('modalCompra').classList.add('hidden');
  document.body.style.overflow = '';
}

async function submitFormCompra(e) {
  e.preventDefault();
  const payload = {
    nome_alimento: document.getElementById('compraNome').value.trim(),
    quantidade: document.getElementById('compraQuantidade').value.trim(),
    unidade: document.getElementById('compraUnidade').value,
  };
  const resp = await apiFetch('/compras/adicionar_compra.php', { method: 'POST', body: payload });
  if (resp.sucesso) {
    fecharModalCompra();
    const listaResp = await apiFetch('/compras/listar_compras.php');
    ESTADO.compras = listaResp.lista_compras || [];
    renderCompras();
    msgFeedback('compraMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('compraMsg', 'erro', resp.mensagem || 'Erro ao adicionar item.');
  }
}

async function toggleCompra(id) {
  const resp = await apiFetch('/compras/editar_compra.php', { method: 'PATCH', body: { id } });
  if (resp.sucesso) {
    const item = ESTADO.compras.find((c) => c.id === id);
    const ficouComprado = item && !item.comprado;
    if (item) item.comprado = !item.comprado;
    renderCompras();
    // Marcar como comprado soma a quantidade no estoque (ou cria o item lá);
    // recarrega o inventário para refletir isso na tela.
    if (ficouComprado) {
      const alimentosResp = await apiFetch('/estoque/listar_alimentos.php');
      ESTADO.alimentos = alimentosResp.alimentos || [];
      renderInventario();
      renderRelatorios();
    }
  }
}

async function removerCompra(id) {
  if (!(await abrirConfirm('Remover este item da sua lista de compras?', { titulo: 'Remover item' }))) return;
  const resp = await apiFetch('/compras/editar_compra.php', { method: 'DELETE', body: { id } });
  if (resp.sucesso) {
    ESTADO.compras = ESTADO.compras.filter((c) => c.id !== id);
    renderCompras();
  }
}

// ══════════════════════════════════════════════════════════════
// GRUPOS (só de alimentos — grupos de receitas saiu junto com a
// antiga feature "Minhas Receitas", substituída pela Biblioteca)
// ══════════════════════════════════════════════════════════════
function renderGruposAlimentos() {
  const selGrupo = document.getElementById('selGrupoAlimento');
  const selAlimento = document.getElementById('selAlimentoParaGrupo');
  selGrupo.innerHTML = ESTADO.gruposAlimentos.map((g) => `<option value="${g.id}">${esc(g.nome)}</option>`).join('') || '<option disabled selected>Crie um grupo primeiro</option>';
  selAlimento.innerHTML = ESTADO.alimentos.map((a) => `<option value="${a.id}">${esc(a.nome)}</option>`).join('') || '<option disabled selected>Nenhum alimento no estoque</option>';

  document.getElementById('gruposAlimentosGrid').innerHTML = ESTADO.gruposAlimentos.map((g) => `
    <div class="grupo-card">
      <div class="grupo-nome"><i class="bi bi-collection-fill"></i> ${esc(g.nome)}</div>
      <div class="grupo-itens">
        ${g.alimentos.map((a) => `<span class="grupo-item-tag">${esc(a.nome)} <button type="button" onclick="removerAlimentoDeGrupo(${g.id},${a.id})" title="Remover do grupo"><i class="bi bi-x-lg"></i></button></span>`).join('') || '<span style="color:var(--text-dim);font-size:12px">Nenhum alimento neste grupo</span>'}
      </div>
    </div>
  `).join('') || '<p style="color:var(--text-muted);font-size:13px">Nenhum grupo de alimentos criado ainda.</p>';
}

async function submitFormGrupoAlimento(e) {
  e.preventDefault();
  const nome = document.getElementById('nomeGrupoAlimento').value.trim();
  const resp = await apiFetch('/grupos/criar_grupo_alimentos.php', { method: 'POST', body: { nome } });
  if (resp.sucesso) {
    document.getElementById('formGrupoAlimento').reset();
    const r = await apiFetch('/grupos/gerenciar_grupo_alimentos.php');
    ESTADO.gruposAlimentos = r.grupos || [];
    renderGruposAlimentos();
    msgFeedback('grupoMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('grupoMsg', 'erro', resp.mensagem);
  }
}
async function submitFormAddAlimentoGrupo(e) {
  e.preventDefault();
  const grupo_id = parseInt(document.getElementById('selGrupoAlimento').value, 10);
  const alimento_id = parseInt(document.getElementById('selAlimentoParaGrupo').value, 10);
  const resp = await apiFetch('/grupos/gerenciar_grupo_alimentos.php', { method: 'POST', body: { grupo_id, alimento_id } });
  if (resp.sucesso) {
    const r = await apiFetch('/grupos/gerenciar_grupo_alimentos.php');
    ESTADO.gruposAlimentos = r.grupos || [];
    renderGruposAlimentos();
    msgFeedback('grupoMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('grupoMsg', 'erro', resp.mensagem);
  }
}
async function removerAlimentoDeGrupo(grupo_id, alimento_id) {
  const resp = await apiFetch('/grupos/gerenciar_grupo_alimentos.php', { method: 'DELETE', body: { grupo_id, alimento_id } });
  if (resp.sucesso) {
    const r = await apiFetch('/grupos/gerenciar_grupo_alimentos.php');
    ESTADO.gruposAlimentos = r.grupos || [];
    renderGruposAlimentos();
  }
}

// ══════════════════════════════════════════════════════════════
// RELATÓRIOS
// ══════════════════════════════════════════════════════════════
function renderRelatorios() {
  const qtdAlimentos = ESTADO.alimentos.length;
  const qtdReceitas = receitasFavoritas().length;

  renderStatsCards(qtdAlimentos, qtdReceitas, ESTADO.movimentacoes);
  renderValidadeEstoque();
  renderGraficoConsumoDesperdicio(ESTADO.movimentacoes?.serie_dias || []);
  renderGaugeAproveitamento(ESTADO.movimentacoes);
}

// ── CARDS DE DESTAQUE ────────────────────────────────────────────
function renderStatsCards(qtdAlimentos, qtdReceitas, mov) {
  const totalDesperdicio = mov?.total_desperdicio ?? 0;
  const maisConsumido = mov?.mais_consumido;

  const cards = [
    { icone: 'bi-box-seam-fill', cor: 'good', valor: qtdAlimentos, label: 'No Estoque' },
    { icone: 'bi-journal-richtext', cor: 'good', valor: qtdReceitas, label: 'Receitas Favoritas' },
    { icone: 'bi-trash3-fill', cor: 'bad', valor: totalDesperdicio, label: 'Desperdício (30 dias)' },
  ];

  const destaque = maisConsumido
    ? `<span class="stat-card-val stat-card-val-text">${esc(maisConsumido.nome)}</span><span class="stat-card-label">Mais consumido · ${maisConsumido.eventos}x</span>`
    : `<span class="stat-card-val stat-card-val-text">—</span><span class="stat-card-label">Mais consumido</span>`;

  document.getElementById('relStatsGrid').innerHTML = cards.map((c) => `
    <div class="stat-card">
      <div class="stat-card-icon stat-card-icon-${c.cor}"><i class="bi ${c.icone}"></i></div>
      <div class="stat-card-body">
        <span class="stat-card-val">${c.valor}</span>
        <span class="stat-card-label">${c.label}</span>
      </div>
    </div>
  `).join('') + `
    <div class="stat-card stat-card-highlight">
      <div class="stat-card-icon stat-card-icon-good"><i class="bi bi-award-fill"></i></div>
      <div class="stat-card-body">${destaque}</div>
    </div>
  `;
}

// ── SITUAÇÃO DE VALIDADE ──────────────────────────────────────────
function renderValidadeEstoque() {
  const comStatus = ESTADO.alimentos.map((a) => {
    const dias = diasValidade(a.validade);
    return { alimento: a, dias, classe: classeValidade(dias) };
  }).sort((a, b) => a.dias - b.dias);

  const vencidos = comStatus.filter((x) => x.classe === 'danger').length;
  const proximos = comStatus.filter((x) => x.classe === 'warning').length;
  const emDia = comStatus.length - vencidos - proximos;

  document.getElementById('relValidadeResumo').innerHTML = `
    <div class="rel-validade-pill danger"><i class="bi bi-x-octagon-fill"></i> ${vencidos} vencido${vencidos === 1 ? '' : 's'}</div>
    <div class="rel-validade-pill warning"><i class="bi bi-exclamation-triangle-fill"></i> ${proximos} vencendo</div>
    <div class="rel-validade-pill good"><i class="bi bi-check-circle-fill"></i> ${emDia} em dia</div>
  `;

  const lista = document.getElementById('relAlertaLista');
  if (comStatus.length === 0) {
    lista.innerHTML = `<p class="rel-vazio">Adicione alimentos ao inventário para acompanhar a validade aqui.</p>`;
    return;
  }
  lista.innerHTML = comStatus.map(({ alimento, dias, classe }) => `
    <div class="rel-validade-item ${classe}">
      <div class="rel-validade-icon"><i class="bi bi-egg-fried"></i></div>
      <div class="rel-validade-info">
        <span class="rel-validade-nome">${esc(alimento.nome)}</span>
        <span class="rel-validade-data">Validade: ${formatDiaCurto(alimento.validade)}</span>
      </div>
      <span class="rel-validade-prazo">${textoValidade(dias)}</span>
    </div>`).join('');
}

// ── GRÁFICO: consumo x desperdício (linha, últimos 30 dias) ─────
function niceMax(v) {
  if (v <= 4) return Math.max(2, v);
  const mag = Math.pow(10, Math.floor(Math.log10(v)));
  const norm = v / mag;
  const step = norm <= 1 ? 1 : norm <= 2 ? 2 : norm <= 5 ? 5 : 10;
  return step * mag;
}
function formatDiaCurto(iso) {
  const [, mes, dia] = iso.split('-');
  return `${dia}/${mes}`;
}

function renderGraficoConsumoDesperdicio(serie) {
  const wrap = document.getElementById('relGraficoLinha');
  const legenda = document.getElementById('relLinhaLegenda');

  legenda.innerHTML = `
    <span class="rel-legend-item"><span class="rel-legend-key" style="background:var(--waste-good)"></span>Consumido</span>
    <span class="rel-legend-item"><span class="rel-legend-key" style="background:var(--waste-bad)"></span>Desperdiçado</span>
  `;

  const temDados = serie.some((d) => d.consumo > 0 || d.desperdicio > 0);
  if (serie.length === 0 || !temDados) {
    wrap.innerHTML = `<p style="color:var(--text-muted);font-size:13px;text-align:center;padding:56px 0">
      <i class="bi bi-graph-up" style="font-size:22px;display:block;margin-bottom:8px;color:var(--text-dim)"></i>
      Ainda sem consumos ou descartes registrados nos últimos 30 dias.
    </p>`;
    return;
  }

  const W = 640, H = 230, padL = 30, padR = 10, padT = 12, padB = 26;
  const plotW = W - padL - padR;
  const plotH = H - padT - padB;
  const n = serie.length;
  const maxVal = Math.max(...serie.map((d) => Math.max(d.consumo, d.desperdicio)));
  const yMax = niceMax(maxVal);

  const xAt = (i) => padL + (n === 1 ? 0 : (i / (n - 1)) * plotW);
  const yAt = (v) => padT + plotH - (v / yMax) * plotH;

  const pathDe = (campo) => serie.map((d, i) => `${i === 0 ? 'M' : 'L'}${xAt(i).toFixed(1)},${yAt(d[campo]).toFixed(1)}`).join(' ');

  const yTicks = [0, yMax / 2, yMax];
  const gridSvg = yTicks.map((t) => `
    <line x1="${padL}" y1="${yAt(t).toFixed(1)}" x2="${W - padR}" y2="${yAt(t).toFixed(1)}" class="rel-grid-line" />
    <text x="${padL - 8}" y="${(yAt(t) + 3).toFixed(1)}" class="rel-axis-label" text-anchor="end">${Number.isInteger(t) ? t : t.toFixed(1)}</text>
  `).join('');

  const passoLabel = Math.ceil(n / 6);
  const xLabelsSvg = serie.map((d, i) => (i % passoLabel === 0 || i === n - 1)
    ? `<text x="${xAt(i).toFixed(1)}" y="${H - 6}" class="rel-axis-label" text-anchor="middle">${formatDiaCurto(d.data)}</text>`
    : '').join('');

  const lastI = n - 1;
  wrap.innerHTML = `
    <svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Gráfico de consumo e desperdício nos últimos 30 dias">
      ${gridSvg}
      <path d="${pathDe('consumo')}" class="rel-line" stroke="var(--waste-good)" />
      <path d="${pathDe('desperdicio')}" class="rel-line" stroke="var(--waste-bad)" />
      <circle cx="${xAt(lastI).toFixed(1)}" cy="${yAt(serie[lastI].consumo).toFixed(1)}" r="4" class="rel-end-dot" fill="var(--waste-good)" />
      <circle cx="${xAt(lastI).toFixed(1)}" cy="${yAt(serie[lastI].desperdicio).toFixed(1)}" r="4" class="rel-end-dot" fill="var(--waste-bad)" />
      ${xLabelsSvg}
      <line x1="0" y1="${padT}" x2="0" y2="${H - padB}" class="rel-crosshair" id="relCrosshair" />
      <rect x="${padL}" y="${padT}" width="${plotW}" height="${plotH}" fill="transparent" id="relHoverArea" style="cursor:crosshair" />
    </svg>
    <div class="rel-tooltip" id="relTooltip"></div>
  `;

  const svg = wrap.querySelector('svg');
  const hoverArea = wrap.querySelector('#relHoverArea');
  const crosshair = wrap.querySelector('#relCrosshair');
  const tooltip = wrap.querySelector('#relTooltip');

  function mostrarTooltip(evt) {
    const rectSvg = svg.getBoundingClientRect();
    const xSvg = ((evt.clientX - rectSvg.left) / rectSvg.width) * W;
    let i = Math.round(((xSvg - padL) / plotW) * (n - 1));
    i = Math.max(0, Math.min(n - 1, i));
    const d = serie[i];

    crosshair.setAttribute('x1', xAt(i).toFixed(1));
    crosshair.setAttribute('x2', xAt(i).toFixed(1));
    crosshair.style.opacity = 1;

    const rectWrap = wrap.getBoundingClientRect();
    const xPx = (xAt(i) / W) * rectWrap.width;
    tooltip.innerHTML = `
      <div class="rel-tooltip-data">${formatDiaCurto(d.data)}</div>
      <div class="rel-tooltip-row"><span class="rel-tooltip-key" style="background:var(--waste-good)"></span>Consumido<span class="rel-tooltip-val">${d.consumo}</span></div>
      <div class="rel-tooltip-row"><span class="rel-tooltip-key" style="background:var(--waste-bad)"></span>Desperdiçado<span class="rel-tooltip-val">${d.desperdicio}</span></div>
    `;
    tooltip.classList.add('visible');
    const tooltipW = tooltip.offsetWidth;
    let left = xPx + 14;
    if (left + tooltipW > rectWrap.width) left = xPx - tooltipW - 14;
    tooltip.style.left = `${left}px`;
    tooltip.style.top = '6px';
  }
  function esconderTooltip() {
    crosshair.style.opacity = 0;
    tooltip.classList.remove('visible');
  }
  hoverArea.addEventListener('pointermove', mostrarTooltip);
  hoverArea.addEventListener('pointerleave', esconderTooltip);
}

// ── GRÁFICO: taxa de aproveitamento (gauge) ──────────────────────
function renderGaugeAproveitamento(mov) {
  const wrap = document.getElementById('relGauge');
  const taxa = mov?.taxa_aproveitamento;
  const totalConsumo = mov?.total_consumo || 0;
  const totalDesperdicio = mov?.total_desperdicio || 0;

  if (taxa === null || taxa === undefined) {
    wrap.innerHTML = `<p style="color:var(--text-muted);font-size:13px;text-align:center">
      <i class="bi bi-speedometer2" style="font-size:22px;display:block;margin-bottom:8px;color:var(--text-dim)"></i>
      Sem movimentações nos últimos 30 dias.
    </p>`;
    return;
  }

  const r = 80, cx = 100, cy = 100, sw = 14;
  const circ = Math.PI * r;
  const dashFilled = (circ * taxa) / 100;

  wrap.innerHTML = `
    <svg viewBox="0 0 200 118" role="img" aria-label="Taxa de aproveitamento: ${taxa}%">
      <path d="M${cx - r},${cy} A${r},${r} 0 0 1 ${cx + r},${cy}" fill="none" stroke="var(--waste-good-dim)" stroke-width="${sw}" stroke-linecap="round" />
      <path d="M${cx - r},${cy} A${r},${r} 0 0 1 ${cx + r},${cy}" fill="none" stroke="var(--waste-good)" stroke-width="${sw}" stroke-linecap="round"
        stroke-dasharray="${dashFilled.toFixed(1)} ${circ.toFixed(1)}" />
    </svg>
    <div class="rel-gauge-info">
      <div class="rel-gauge-valor">${taxa}%</div>
      <div class="rel-gauge-legenda">aproveitado nos últimos 30 dias<br>${totalConsumo} consumo(s) · ${totalDesperdicio} descarte(s)</div>
    </div>
  `;
}

// ══════════════════════════════════════════════════════════════
// CONFIGURAÇÕES
// ══════════════════════════════════════════════════════════════
function renderConfig() {
  const cfg = ESTADO.config;
  if (!cfg) return;
  const iniciais = iniciaisNome(cfg.username);
  const plano = cfg.plano === 'premium' ? 'Premium' : 'Free';

  document.getElementById('cfgAvatar').textContent = iniciais;
  document.getElementById('editAvatar').textContent = iniciais;
  document.getElementById('cfgNome').textContent = cfg.username;
  document.getElementById('cfgEmailResumo').textContent = cfg.email;
  document.getElementById('cfgPlanoResumo').textContent = plano;
  document.getElementById('cfgQtdAlimentos').textContent = ESTADO.alimentos.length;
  document.getElementById('cfgQtdReceitas').textContent = receitasFavoritas().length;

  document.getElementById('viewUsername').textContent = cfg.username;
  document.getElementById('viewEmail').textContent = cfg.email;
  document.getElementById('perfilUsername').value = cfg.username;
  document.getElementById('perfilEmail').value = cfg.email;

  document.getElementById('toggleModoTela').classList.toggle('active', cfg.modo_tela === 'escuro');
  document.getElementById('toggleAlertas').classList.toggle('active', !!cfg.alertas_validade);
}

function toggleEditPerfil(abrir) {
  document.getElementById('viewPerfil').style.display = abrir ? 'none' : '';
  document.getElementById('editPerfil').classList.toggle('open', abrir);
}
function toggleEditSenha(abrir) {
  document.getElementById('viewSenha').style.display = abrir ? 'none' : '';
  document.getElementById('editSenha').classList.toggle('open', abrir);
  if (!abrir) document.getElementById('formSenha').reset();
}

async function submitFormPerfil(e) {
  e.preventDefault();
  const payload = {
    username: document.getElementById('perfilUsername').value.trim(),
    email: document.getElementById('perfilEmail').value.trim(),
  };
  const resp = await apiFetch('/configuracoes/atualizar_configuracoes.php', { method: 'POST', body: payload });
  if (resp.sucesso) {
    const r = await apiFetch('/configuracoes/listar_configuracoes.php');
    ESTADO.config = r.configuracoes;
    ESTADO.usuario.username = ESTADO.config.username;
    renderSidebar();
    renderConfig();
    toggleEditPerfil(false);
    msgFeedback('perfilMsg', 'ok', 'Perfil atualizado com sucesso!');
  } else {
    msgFeedback('perfilMsg', 'erro', resp.mensagem || 'Erro ao atualizar perfil.');
  }
}

async function submitFormSenha(e) {
  e.preventDefault();
  const payload = {
    senha_atual: document.getElementById('senhaAtual').value.trim(),
    senha_nova: document.getElementById('senhaNova').value.trim(),
    senha_conf: document.getElementById('senhaConf').value.trim(),
  };
  const resp = await apiFetch('/configuracoes/atualizar_configuracoes.php', { method: 'POST', body: payload });
  if (resp.sucesso) {
    toggleEditSenha(false);
    msgFeedback('senhaMsg', 'ok', 'Senha alterada com sucesso!');
  } else {
    msgFeedback('senhaMsg', 'erro', resp.mensagem || 'Erro ao alterar senha.');
  }
}

// Preferências (modo de tela e alertas): persistidas em FS_configuracoes.
// Observação: o design original é um tema único fixo; o toggle abaixo
// grava a preferência real no banco, mas não há uma paleta clara
// implementada nesta refatoração para não alterar o design existente.
async function alternarModoTela() {
  const novo = ESTADO.config.modo_tela === 'escuro' ? 'claro' : 'escuro';
  const resp = await apiFetch('/configuracoes/atualizar_configuracoes.php', { method: 'POST', body: { modo_tela: novo } });
  if (resp.sucesso) {
    ESTADO.config.modo_tela = novo;
    document.getElementById('toggleModoTela').classList.toggle('active', novo === 'escuro');
  }
}
async function alternarAlertas() {
  const novo = !ESTADO.config.alertas_validade;
  const resp = await apiFetch('/configuracoes/atualizar_configuracoes.php', { method: 'POST', body: { alertas_validade: novo } });
  if (resp.sucesso) {
    ESTADO.config.alertas_validade = novo;
    document.getElementById('toggleAlertas').classList.toggle('active', novo);
  }
}

async function fazerLogout() {
  await apiFetch('/usuarios/logout.php', { method: 'POST' });
  window.location.href = 'login.html';
}
async function desativarConta() {
  const ok = await abrirConfirm('Você poderá reativá-la fazendo login novamente quando quiser.', {
    titulo: 'Desativar sua conta?',
    botao: 'Desativar conta',
    icone: 'bi-pause-circle-fill',
  });
  if (!ok) return;
  await apiFetch('/usuarios/desativar_conta.php', { method: 'POST' });
  window.location.href = 'login.html?desativada=1';
}

// ── MOBILE SIDEBAR ───────────────────────
function toggleSidebar(forceClose) {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebarOverlay');
  if (forceClose) {
    sidebar.classList.remove('open');
    overlay.classList.remove('open');
    overlay.classList.add('hidden');
    return;
  }
  sidebar.classList.toggle('open');
  overlay.classList.toggle('open');
  overlay.classList.toggle('hidden');
}

// ── INICIALIZAÇÃO ─────────────────────────────────────────────
async function main() {
  const check = await apiFetch('/usuarios/check_login.php');
  if (!check.sucesso) {
    window.location.href = 'login.html';
    return;
  }
  ESTADO.usuario = check.usuario;

  bindNav();
  document.getElementById('formInv').addEventListener('submit', submitFormInv);
  document.getElementById('formMov').addEventListener('submit', submitFormMov);
  document.getElementById('formCompra').addEventListener('submit', submitFormCompra);
  document.getElementById('formGrupoAlimento').addEventListener('submit', submitFormGrupoAlimento);
  document.getElementById('formAddAlimentoGrupo').addEventListener('submit', submitFormAddAlimentoGrupo);
  document.getElementById('formPerfil').addEventListener('submit', submitFormPerfil);
  document.getElementById('formSenha').addEventListener('submit', submitFormSenha);

  // Fecha o dropdown de sugestões de ingrediente (aba Criar) ao clicar fora
  document.addEventListener('click', fecharSugestoesCriarSeFora);

  // Fecha modais clicando fora ou com ESC (igual ao comportamento original)
  document.getElementById('modalInv').addEventListener('click', (e) => {
    if (e.target.id === 'modalInv') fecharModalInv();
  });
  document.getElementById('modalMov').addEventListener('click', (e) => {
    if (e.target.id === 'modalMov') fecharModalMov();
  });
  document.getElementById('modalCompra').addEventListener('click', (e) => {
    if (e.target.id === 'modalCompra') fecharModalCompra();
  });
  document.getElementById('modalReceita').addEventListener('click', (e) => {
    if (e.target.id === 'modalReceita') fecharModalReceita();
  });
  document.getElementById('modalConfirm').addEventListener('click', (e) => {
    if (e.target.id === 'modalConfirm') fecharConfirm(false);
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      fecharModalInv();
      fecharModalMov();
      fecharModalCompra();
      fecharModalReceita();
      fecharConfirm(false);
    }
  });

  await carregarTudo();
  renderTudo();

  const secInicial = (location.hash || '#inventario').replace('#', '');
  mostrarSecao(secInicial);
}

document.addEventListener('DOMContentLoaded', main);
