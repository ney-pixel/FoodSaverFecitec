// Usado quando compilado para Web (Flutter Web/Chrome).
//
// No navegador, JavaScript não tem permissão de ler o cabeçalho
// "Set-Cookie" da resposta nem de escrever o cabeçalho "Cookie" na
// requisição (são bloqueados por segurança do próprio navegador) — então
// o esquema manual de cookie do ApiCliente não tem efeito nenhum aqui.
// Quem precisa guardar e reenviar o cookie de sessão automaticamente é o
// próprio navegador, e para isso o cliente precisa pedir explicitamente
// para incluir credenciais (cookies) mesmo em requisições entre portas
// diferentes (ex: app em :5000 chamando a API em :8000).
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client criarClienteHttp() => BrowserClient()..withCredentials = true;
