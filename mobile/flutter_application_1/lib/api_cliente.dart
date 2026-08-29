// Cliente HTTP central para conversar com a API PHP (FoodSaverFecitec/api).
//
// A API usa sessão PHP (cookie), não token: o login cria a sessão no
// servidor e devolve um "Set-Cookie" com o PHPSESSID, que precisa ser
// reenviado em toda requisição seguinte para o servidor saber quem
// somos. Aqui guardamos esse cookie em memória e no SharedPreferences,
// para o usuário continuar logado mesmo depois de fechar o app.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'http_cliente_web.dart' if (dart.library.io) 'http_cliente_nativo.dart'
    as plataforma;

/// Erro de comunicação com a API: tanto falhas de rede/timeout quanto
/// respostas de negócio com "sucesso": false (ex: senha incorreta,
/// validação, sessão expirada etc).
class ApiException implements Exception {
  final String mensagem;
  final int? statusHttp;
  final Map<String, String>? erros;

  ApiException(this.mensagem, {this.statusHttp, this.erros});

  @override
  String toString() => mensagem;
}

class ApiCliente {
  ApiCliente._();

  // ─────────────────────────────────────────────
  // Endereço onde a API PHP (pasta api/) está rodando.
  //
  // Para a apresentação do TCC: a API roda localmente na mesma máquina
  // via `php -S localhost:8000` (executado na raiz do projeto, onde fica
  // a pasta api/), enquanto o banco MySQL continua no servidor da escola
  // (143.106.241.4) — só a API PHP em si é local.
  //
  // "localhost" aqui só funciona quando o Flutter roda NA MESMA MÁQUINA
  // que o `php -S` (Windows desktop, Chrome/web, ou um emulador que
  // mapeie localhost do host — o Android Studio/emulador Android padrão
  // NÃO conta: nele "localhost" aponta pro próprio emulador, então seria
  // preciso trocar para 'http://10.0.2.2:8000/api'; em um celular físico
  // na mesma rede Wi-Fi, use o IP local da máquina, ex. 'http://192.168.x.x:8000/api').
  // ─────────────────────────────────────────────
  static const String baseUrl = 'http://localhost:8000/api';

  // No navegador (Flutter Web), JS não consegue ler "Set-Cookie" nem
  // escrever "Cookie" manualmente — é o próprio navegador que guarda e
  // reenvia o cookie de sessão, desde que o cliente HTTP peça pra incluir
  // credenciais (ver http_cliente_web.dart). Por isso todo o controle
  // manual de cookie abaixo só roda fora da Web.
  static final http.Client _cliente = plataforma.criarClienteHttp();

  static const _chaveCookie = 'foodsaver_cookie_sessao';
  static String? _cookie;
  static bool _cookieCarregado = false;

  static Future<void> _carregarCookie() async {
    if (kIsWeb || _cookieCarregado) return;
    final prefs = await SharedPreferences.getInstance();
    _cookie = prefs.getString(_chaveCookie);
    _cookieCarregado = true;
  }

  static Future<void> _salvarCookie(String? valor) async {
    if (kIsWeb) return;
    _cookie = valor;
    _cookieCarregado = true;
    final prefs = await SharedPreferences.getInstance();
    if (valor == null) {
      await prefs.remove(_chaveCookie);
    } else {
      await prefs.setString(_chaveCookie, valor);
    }
  }

  static void _guardarCookieDaResposta(http.Response resposta) {
    if (kIsWeb) return;
    final setCookie = resposta.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return;
    // O header pode vir com atributos (Path=/, HttpOnly...): guardamos só o par nome=valor.
    final parPrincipal = setCookie.split(';').first.trim();
    if (parPrincipal.isNotEmpty) {
      _salvarCookie(parPrincipal);
    }
  }

  static Future<Map<String, dynamic>> _requisitar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? corpo,
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await _carregarCookie();

    var uri = Uri.parse('$baseUrl$caminho');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }

    final cookieAtual = _cookie;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // No navegador, "Cookie" é um header proibido pro JS setar — quem
      // cuida disso é o próprio navegador (ver withCredentials no cliente web).
      if (!kIsWeb && cookieAtual != null) 'Cookie': cookieAtual,
    };
    final corpoJson = corpo != null ? jsonEncode(corpo) : null;

    http.Response resposta;
    try {
      switch (metodo) {
        case 'GET':
          resposta = await _cliente
              .get(uri, headers: headers)
              .timeout(timeout);
          break;
        case 'POST':
          resposta = await _cliente
              .post(uri, headers: headers, body: corpoJson)
              .timeout(timeout);
          break;
        case 'PUT':
          resposta = await _cliente
              .put(uri, headers: headers, body: corpoJson)
              .timeout(timeout);
          break;
        case 'PATCH':
          resposta = await _cliente
              .patch(uri, headers: headers, body: corpoJson)
              .timeout(timeout);
          break;
        case 'DELETE':
          resposta = await _cliente
              .delete(uri, headers: headers, body: corpoJson)
              .timeout(timeout);
          break;
        default:
          throw ApiException('Método HTTP não suportado: $metodo');
      }
    } on TimeoutException {
      throw ApiException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw ApiException(
          'Não foi possível conectar ao servidor. Verifique sua internet.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Não foi possível conectar ao servidor.');
    }

    _guardarCookieDaResposta(resposta);

    Map<String, dynamic> json;
    try {
      final decodificado = jsonDecode(resposta.body);
      if (decodificado is! Map<String, dynamic>) {
        throw const FormatException('Formato inesperado');
      }
      json = decodificado;
    } catch (_) {
      throw ApiException('Resposta inválida do servidor.',
          statusHttp: resposta.statusCode);
    }

    final sucesso = json['sucesso'] == true;
    if (!sucesso) {
      Map<String, String>? erros;
      if (json['erros'] is Map) {
        erros = (json['erros'] as Map)
            .map((chave, valor) => MapEntry(chave.toString(), valor.toString()));
      }
      final mensagem = (json['mensagem'] as String?);
      throw ApiException(
        mensagem != null && mensagem.isNotEmpty
            ? mensagem
            : 'Não foi possível concluir a operação.',
        statusHttp: resposta.statusCode,
        erros: erros,
      );
    }

    return json;
  }

  static Future<Map<String, dynamic>> get(String caminho,
          {Map<String, String>? query}) =>
      _requisitar('GET', caminho, query: query);

  static Future<Map<String, dynamic>> post(String caminho,
          {Map<String, dynamic>? corpo, Duration? timeout}) =>
      _requisitar('POST', caminho,
          corpo: corpo, timeout: timeout ?? const Duration(seconds: 15));

  static Future<Map<String, dynamic>> put(String caminho,
          {Map<String, dynamic>? corpo}) =>
      _requisitar('PUT', caminho, corpo: corpo);

  static Future<Map<String, dynamic>> patch(String caminho,
          {Map<String, dynamic>? corpo}) =>
      _requisitar('PATCH', caminho, corpo: corpo);

  static Future<Map<String, dynamic>> delete(String caminho,
          {Map<String, dynamic>? corpo}) =>
      _requisitar('DELETE', caminho, corpo: corpo);

  /// Apaga o cookie de sessão salvo localmente (usado no logout).
  static Future<void> encerrarSessaoLocal() => _salvarCookie(null);

  /// Se existe um cookie de sessão salvo de uma vez anterior.
  /// Não garante que o servidor ainda considera essa sessão válida —
  /// use check_login.php para confirmar.
  ///
  /// No Web não há como saber isso localmente (o navegador guarda o
  /// cookie, não o Dart) — sempre retorna true pra deixar quem chamar
  /// tentar check_login.php e o navegador decidir se manda o cookie.
  static Future<bool> temSessaoSalva() async {
    if (kIsWeb) return true;
    await _carregarCookie();
    return _cookie != null;
  }
}
