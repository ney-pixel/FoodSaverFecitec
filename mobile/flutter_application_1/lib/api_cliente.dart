// Cliente HTTP central para a API PHP — usa sessão via cookie (PHPSESSID),
// guardado em memória e no SharedPreferences para manter o login.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'http_cliente_web.dart' if (dart.library.io) 'http_cliente_nativo.dart'
    as plataforma;

/// Erro de comunicação com a API (rede ou "sucesso": false).
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

  // Base da API — trocar se rodar em emulador/celular físico
  // emulador Android: 10.0.2.2 · celular físico: IP da rede
  static const String baseUrl = 'http://localhost:8000/api';

  // Controle manual de cookie só roda fora da Web (ver http_cliente_web.dart)
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
      // Web: cookie é gerenciado pelo navegador (withCredentials)
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

  /// Se há cookie de sessão salvo (não garante que ainda é válido).
  static Future<bool> temSessaoSalva() async {
    if (kIsWeb) return true;
    await _carregarCookie();
    return _cookie != null;
  }
}
