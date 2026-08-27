// ══════════════════════════════════════════════════════════════
// FoodSaver — Perfil (SPA client-side)
// Toda a lógica de acesso ao banco foi movida para ../../api/.
// Este arquivo só busca dados via fetch() e desenha a interface,
// preservando o layout/CSS original de perfil.php.
// ══════════════════════════════════════════════════════════════

const ESTADO = {
  usuario: null,
  alimentos: [],
  receitas: [],
  compras: [],
  gruposAlimentos: [],
  gruposReceitas: [],
  config: null,
};

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
  const [alimentosResp, receitasResp, comprasResp, configResp, gAlResp, gReResp] = await Promise.all([
    apiFetch('/estoque/listar_alimentos.php'),
    apiFetch('/receitas/listar_receitas.php'),
    apiFetch('/compras/listar_compras.php'),
    apiFetch('/configuracoes/listar_configuracoes.php'),
    apiFetch('/grupos/gerenciar_grupo_alimentos.php'),
    apiFetch('/grupos/gerenciar_grupo_receitas.php'),
  ]);
  ESTADO.alimentos = alimentosResp.alimentos || [];
  ESTADO.receitas = receitasResp.receitas || [];
  ESTADO.compras = comprasResp.lista_compras || [];
  ESTADO.config = configResp.configuracoes || null;
  ESTADO.gruposAlimentos = gAlResp.grupos || [];
  ESTADO.gruposReceitas = gReResp.grupos || [];
}

function renderTudo() {
  renderSidebar();
  renderInventario();
  renderReceitas();
  renderCompras();
  renderGruposAlimentos();
  renderGruposReceitas();
  renderRelatorios();
  renderConfig();
}

// ── SIDEBAR ───────────────────────────────────────────────────
function renderSidebar() {
  const qtdAlimentos = ESTADO.alimentos.length;
  const qtdReceitas = ESTADO.receitas.length;
  const nivel = Math.floor(qtdReceitas / 2) + 1;
  const plano = (ESTADO.config?.plano || 'gratuito') === 'premium' ? 'Premium' : 'Free';
  const nome = ESTADO.usuario?.username || '';

  document.getElementById('sbAvatar').textContent = iniciaisNome(nome);
  document.getElementById('sbNivel').textContent = nivel;
  document.getElementById('sbNome').textContent = nome;
  document.getElementById('sbPlano').textContent = `Plano ${plano}`;

  const xp = qtdAlimentos * 50;
  document.getElementById('xpCount').textContent = `${xp} / 2.000`;
  document.getElementById('xpFill').style.width = `${Math.min(100, xp / 20)}%`;
  document.getElementById('xpLabel').textContent = `Próximo nível: ${nivel + 1}`;
}

// ── NAVEGAÇÃO ENTRE SEÇÕES ───────────────────────────────────
const SECOES = ['inventario', 'receitas', 'compras', 'grupos', 'planos', 'relatorios', 'config'];
function mostrarSecao(sec) {
  if (!SECOES.includes(sec)) sec = 'inventario';
  SECOES.forEach((s) => document.getElementById(s).classList.toggle('hidden', s !== sec));
  document.querySelectorAll('.nav-item').forEach((el) => el.classList.toggle('active', el.dataset.sec === sec));
  history.replaceState(null, '', `#${sec}`);
  if (sec === 'relatorios') setTimeout(animateMetricBars, 150);
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
        <button type="button" class="inv-btn edit" title="Editar" onclick="abrirModalEdit(${it.id})"><i class="bi bi-pencil-fill"></i></button>
        <button type="button" class="inv-btn delete" title="Excluir" onclick="excluirAlimento(${it.id})"><i class="bi bi-trash3-fill"></i></button>
      </div>
      <div class="inv-status-bar ${classe}"></div>
    </div>`;
  }).join('');
}

function abrirModalAdd() {
  document.getElementById('modalInvTitulo').textContent = 'Adicionar Alimento';
  document.getElementById('invSubmitBtn').textContent = 'Adicionar';
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
  document.getElementById('invSubmitBtn').textContent = 'Salvar Alterações';
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
    msgFeedback('invMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('invMsg', 'erro', resp.mensagem || 'Erro ao salvar item.');
  }
}

async function excluirAlimento(id) {
  if (!confirm('Remover este item?')) return;
  const resp = await apiFetch('/estoque/excluir_alimento.php', { method: 'DELETE', body: { id } });
  if (resp.sucesso) {
    await carregarTudo();
    renderInventario();
    renderRelatorios();
    renderConfig();
    renderGruposAlimentos();
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

// ══════════════════════════════════════════════════════════════
// RECEITAS
// ══════════════════════════════════════════════════════════════
function mudarTabReceita(tab) {
  document.querySelectorAll('.rtab-btn[data-tab]').forEach((b) => b.classList.toggle('active', b.dataset.tab === tab));
  document.getElementById('tabReceitasSalvas').classList.toggle('hidden', tab !== 'salvas');
  document.getElementById('tabReceitaCriar').classList.toggle('hidden', tab !== 'criar');
  if (tab === 'criar') renderIngredientesCheckboxes();
}

function renderReceitas() {
  document.getElementById('recEmpty').style.display = ESTADO.receitas.length === 0 ? '' : 'none';
  document.getElementById('receitasGrid').innerHTML = ESTADO.receitas.map((rec) => `
    <div class="receita-card-saved">
      <div class="rc-head">
        <div>
          <div class="rc-titulo">${esc(rec.titulo)}</div>
          ${rec.porcoes ? `<div class="rc-meta" style="margin-top:6px">
            <span class="rc-tag"><i class="bi bi-people-fill"></i> ${rec.porcoes} ${rec.porcoes === 1 ? 'porção' : 'porções'}</span>
          </div>` : ''}
        </div>
        <div style="display:flex;gap:6px">
          <button type="button" class="rc-fav ${rec.favorito ? 'active' : ''}" title="Favoritar" onclick="favoritarReceita(${rec.id})">
            <i class="bi ${rec.favorito ? 'bi-star-fill' : 'bi-star'}"></i>
          </button>
          <button type="button" class="rc-delete" onclick="excluirReceita(${rec.id})"><i class="bi bi-trash3-fill"></i></button>
        </div>
      </div>
      ${rec.descricao ? `<div class="rc-desc">${esc(rec.descricao).replace(/\n/g, '<br>')}</div>` : ''}
      ${rec.ingredientes?.length ? `<div class="rc-ings">${rec.ingredientes.map((i) => `<span class="rc-ing">${esc(i)}</span>`).join('')}</div>` : ''}
      ${rec.modo_preparo ? `<div style="font-size:12px;color:var(--text-muted);margin-top:4px"><i class="bi bi-list-check"></i> ${esc(rec.modo_preparo).replace(/\n/g, '<br>')}</div>` : ''}
    </div>
  `).join('');
}

function renderIngredientesCheckboxes() {
  const wrap = document.getElementById('recIngCheckboxes');
  if (ESTADO.alimentos.length === 0) {
    document.getElementById('recIngWrap').innerHTML =
      '<p style="color:var(--text-muted);font-size:13px"><i class="bi bi-info-circle"></i> Adicione itens ao inventário para selecioná-los aqui.</p>';
    return;
  }
  wrap.innerHTML = ESTADO.alimentos.map((it) => {
    const dias = diasValidade(it.validade);
    const classe = classeValidade(dias);
    return `<label class="ing-chk-label">
      <input type="checkbox" value="${it.id}">
      ${esc(it.nome)}
      <span class="expiry-pill ${classe}">${Math.abs(dias)}d</span>
    </label>`;
  }).join('');
}

async function submitFormReceita(e) {
  e.preventDefault();
  const ingredientesSel = Array.from(document.querySelectorAll('#recIngCheckboxes input:checked')).map((el) => parseInt(el.value, 10));
  const payload = {
    titulo: document.getElementById('recTitulo').value.trim(),
    descricao: document.getElementById('recDescricao').value.trim(),
    modo_preparo: document.getElementById('recModoPreparo').value.trim(),
    porcoes: parseInt(document.getElementById('recPorcoes').value, 10) || 2,
    ingredientes_sel: ingredientesSel,
  };
  const resp = await apiFetch('/receitas/cadastrar_receita.php', { method: 'POST', body: payload });
  if (resp.sucesso) {
    document.getElementById('formReceita').reset();
    await carregarTudo();
    renderReceitas();
    renderRelatorios();
    renderConfig();
    renderGruposReceitas();
    mudarTabReceita('salvas');
    msgFeedback('recMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('recMsg', 'erro', resp.mensagem || 'Erro ao salvar receita.');
  }
}

async function excluirReceita(id) {
  if (!confirm('Excluir esta receita?')) return;
  const resp = await apiFetch('/receitas/excluir_receita.php', { method: 'DELETE', body: { id } });
  if (resp.sucesso) {
    await carregarTudo();
    renderReceitas();
    renderRelatorios();
    renderConfig();
    renderGruposReceitas();
  } else {
    msgFeedback('recMsg', 'erro', resp.mensagem || 'Erro ao excluir receita.');
  }
}

async function favoritarReceita(id) {
  const resp = await apiFetch('/receitas/favoritar_receita.php', { method: 'POST', body: { id } });
  if (resp.sucesso) {
    const rec = ESTADO.receitas.find((r) => r.id === id);
    if (rec) rec.favorito = resp.favorito;
    renderReceitas();
  }
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
    if (item) item.comprado = !item.comprado;
    renderCompras();
  }
}

async function removerCompra(id) {
  if (!confirm('Remover este item da lista?')) return;
  const resp = await apiFetch('/compras/editar_compra.php', { method: 'DELETE', body: { id } });
  if (resp.sucesso) {
    ESTADO.compras = ESTADO.compras.filter((c) => c.id !== id);
    renderCompras();
  }
}

// ══════════════════════════════════════════════════════════════
// GRUPOS
// ══════════════════════════════════════════════════════════════
function mudarTabGrupo(tab) {
  document.querySelectorAll('.rtab-btn[data-gtab]').forEach((b) => b.classList.toggle('active', b.dataset.gtab === tab));
  document.getElementById('tabGrupoAlimentos').classList.toggle('hidden', tab !== 'alimentos');
  document.getElementById('tabGrupoReceitas').classList.toggle('hidden', tab !== 'receitas');
}

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

function renderGruposReceitas() {
  const selGrupo = document.getElementById('selGrupoReceita');
  const selReceita = document.getElementById('selReceitaParaGrupo');
  selGrupo.innerHTML = ESTADO.gruposReceitas.map((g) => `<option value="${g.id}">${esc(g.nome)}</option>`).join('') || '<option disabled selected>Crie um grupo primeiro</option>';
  selReceita.innerHTML = ESTADO.receitas.map((r) => `<option value="${r.id}">${esc(r.titulo)}</option>`).join('') || '<option disabled selected>Nenhuma receita cadastrada</option>';

  document.getElementById('gruposReceitasGrid').innerHTML = ESTADO.gruposReceitas.map((g) => `
    <div class="grupo-card">
      <div class="grupo-nome"><i class="bi bi-collection-fill"></i> ${esc(g.nome)}</div>
      <div class="grupo-itens">
        ${g.receitas.map((r) => `<span class="grupo-item-tag">${esc(r.titulo)} <button type="button" onclick="removerReceitaDeGrupo(${g.id},${r.id})" title="Remover do grupo"><i class="bi bi-x-lg"></i></button></span>`).join('') || '<span style="color:var(--text-dim);font-size:12px">Nenhuma receita neste grupo</span>'}
      </div>
    </div>
  `).join('') || '<p style="color:var(--text-muted);font-size:13px">Nenhum grupo de receitas criado ainda.</p>';
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

async function submitFormGrupoReceita(e) {
  e.preventDefault();
  const nome = document.getElementById('nomeGrupoReceita').value.trim();
  const resp = await apiFetch('/grupos/criar_grupo_receitas.php', { method: 'POST', body: { nome } });
  if (resp.sucesso) {
    document.getElementById('formGrupoReceita').reset();
    const r = await apiFetch('/grupos/gerenciar_grupo_receitas.php');
    ESTADO.gruposReceitas = r.grupos || [];
    renderGruposReceitas();
    msgFeedback('grupoMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('grupoMsg', 'erro', resp.mensagem);
  }
}
async function submitFormAddReceitaGrupo(e) {
  e.preventDefault();
  const grupo_id = parseInt(document.getElementById('selGrupoReceita').value, 10);
  const receita_id = parseInt(document.getElementById('selReceitaParaGrupo').value, 10);
  const resp = await apiFetch('/grupos/gerenciar_grupo_receitas.php', { method: 'POST', body: { grupo_id, receita_id } });
  if (resp.sucesso) {
    const r = await apiFetch('/grupos/gerenciar_grupo_receitas.php');
    ESTADO.gruposReceitas = r.grupos || [];
    renderGruposReceitas();
    msgFeedback('grupoMsg', 'ok', resp.mensagem);
  } else {
    msgFeedback('grupoMsg', 'erro', resp.mensagem);
  }
}
async function removerReceitaDeGrupo(grupo_id, receita_id) {
  const resp = await apiFetch('/grupos/gerenciar_grupo_receitas.php', { method: 'DELETE', body: { grupo_id, receita_id } });
  if (resp.sucesso) {
    const r = await apiFetch('/grupos/gerenciar_grupo_receitas.php');
    ESTADO.gruposReceitas = r.grupos || [];
    renderGruposReceitas();
  }
}

// ══════════════════════════════════════════════════════════════
// RELATÓRIOS
// ══════════════════════════════════════════════════════════════
function renderRelatorios() {
  const qtdAlimentos = ESTADO.alimentos.length;
  const qtdReceitas = ESTADO.receitas.length;
  const nivel = Math.floor(qtdReceitas / 2) + 1;

  document.getElementById('relAlimentos').textContent = qtdAlimentos;
  document.getElementById('relReceitas').textContent = qtdReceitas;
  document.getElementById('relNivel').textContent = nivel;
  document.getElementById('relEconomia').textContent = `R$${qtdAlimentos * 8}`;

  const metaAlimentos = 20;
  const metaReceitas = 10;
  const pctAlimentos = Math.min(100, Math.round((qtdAlimentos / metaAlimentos) * 100));
  const pctReceitas = Math.min(100, Math.round((qtdReceitas / metaReceitas) * 100));
  const metricas = [
    ['Alimentos no Estoque', `${qtdAlimentos} / ${metaAlimentos} itens`, pctAlimentos],
    ['Receitas Criadas', `${qtdReceitas} / ${metaReceitas} receitas`, pctReceitas],
    ['Score FoodSaver', `Nível ${nivel}`, Math.min(100, nivel * 10)],
  ];
  document.getElementById('metricsList').innerHTML = metricas.map(([lbl, val, pct]) => `
    <div class="metric-item">
      <div class="metric-top"><span class="metric-label">${lbl}</span><span class="metric-val">${val}</span></div>
      <div class="metric-track"><div class="metric-bar" style="width:${pct}%"></div></div>
      <div class="metric-pct">${pct}%</div>
    </div>
  `).join('');
}
function animateMetricBars() {
  document.querySelectorAll('.metric-bar').forEach((bar) => {
    const w = bar.style.width;
    bar.style.transition = 'none';
    bar.style.width = '0%';
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        bar.style.transition = 'width 0.8s cubic-bezier(0.4,0,0.2,1)';
        bar.style.width = w;
      });
    });
  });
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
  document.getElementById('cfgQtdReceitas').textContent = ESTADO.receitas.length;

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
  if (!confirm('Tem certeza que deseja desativar sua conta? Você poderá reativá-la fazendo login novamente.')) return;
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
  document.getElementById('formReceita').addEventListener('submit', submitFormReceita);
  document.getElementById('formCompra').addEventListener('submit', submitFormCompra);
  document.getElementById('formGrupoAlimento').addEventListener('submit', submitFormGrupoAlimento);
  document.getElementById('formAddAlimentoGrupo').addEventListener('submit', submitFormAddAlimentoGrupo);
  document.getElementById('formGrupoReceita').addEventListener('submit', submitFormGrupoReceita);
  document.getElementById('formAddReceitaGrupo').addEventListener('submit', submitFormAddReceitaGrupo);
  document.getElementById('formPerfil').addEventListener('submit', submitFormPerfil);
  document.getElementById('formSenha').addEventListener('submit', submitFormSenha);

  // Fecha modais clicando fora ou com ESC (igual ao comportamento original)
  document.getElementById('modalInv').addEventListener('click', (e) => {
    if (e.target.id === 'modalInv') fecharModalInv();
  });
  document.getElementById('modalCompra').addEventListener('click', (e) => {
    if (e.target.id === 'modalCompra') fecharModalCompra();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      fecharModalInv();
      fecharModalCompra();
    }
  });

  await carregarTudo();
  renderTudo();

  const secInicial = (location.hash || '#inventario').replace('#', '');
  mostrarSecao(secInicial);
}

document.addEventListener('DOMContentLoaded', main);
