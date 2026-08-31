// Cliente HTTP para dart:io (Android/iOS/desktop) — sessão gerenciada manualmente pelo ApiCliente
import 'package:http/http.dart' as http;

http.Client criarClienteHttp() => http.Client();
