//cliente HTTP para web:cookie de sessão é gerenciado pelo navegador (withCredentials)
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client criarClienteHttp() => BrowserClient()..withCredentials = true;
