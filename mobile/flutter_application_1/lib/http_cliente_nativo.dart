// Usado em Android/iOS/Windows/macOS/Linux (qualquer alvo com dart:io).
// Cliente HTTP padrão — aqui a sessão é mantida manualmente pelo
// ApiCliente (lendo o Set-Cookie e reenviando via header Cookie), porque
// não existe navegador cuidando disso.
import 'package:http/http.dart' as http;

http.Client criarClienteHttp() => http.Client();
