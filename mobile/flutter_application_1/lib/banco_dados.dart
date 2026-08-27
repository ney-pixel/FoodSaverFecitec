

import 'alimento.dart';

class BancoDados {
  BancoDados._(); //construtro privado

  //lista de usuarios cadastrados
  static final List<Map<String, String>> usuariosCadastrados = [
    //usuario exemplo pre-definido
    {
      'nome':  'Gabriel Humberto',
      'email': 'gabriel@email.com',
      'senha': '123456',
    },
  ];

  //aqui verifica se o email ja foi cadastrado
  static bool emailJaCadastrado(String email) {
    return usuariosCadastrados
        .any((u) => u['email']!.toLowerCase() == email.toLowerCase());
  }

  //cadastra um novo email e se esse email ja existir retorna false
  static bool cadastrarUsuario(String nome, String email, String senha) {
    if (emailJaCadastrado(email)) return false;
    usuariosCadastrados.add({'nome': nome, 'email': email, 'senha': senha});
    return true;
  }

  //aq busca o usuario pelo email e senha, reotrna mapa ou null
  static Map<String, String>? buscarUsuario(String email, String senha) {
    try {
      return usuariosCadastrados.firstWhere(
        (u) =>
            u['email']!.toLowerCase() == email.toLowerCase() &&
            u['senha'] == senha,
      );
    } catch (_) {
      return null;
    }
  }

  //estoque global de alimentos
  static final List<AlimentoEstoque> estoque = [
    AlimentoEstoque(
      id: '1',
      nome: 'Frango',

      quantidade: 500,
      unidade: 'g',
      validade: '05/01',
      status: 'Urgente',
      entrarNaIA: true,
    ),
    AlimentoEstoque(
      id: '2',
      nome: 'Leite Integral',
 
      quantidade: 1,
      unidade: 'L',
      validade: '06/01',
      status: 'Urgente',
      entrarNaIA: true,
    ),
    AlimentoEstoque(
      id: '3',
      nome: 'Carne Moída',

      quantidade: 300,
      unidade: 'g',
      validade: '08/01',
      status: 'Atenção',
      entrarNaIA: true,
    ),
    AlimentoEstoque(
      id: '4',
      nome: 'Queijo Mussarela',
  
      quantidade: 200,
      unidade: 'g',
      validade: '10/01',
      status: 'Atenção',
      entrarNaIA: false,
    ),

    
    AlimentoEstoque(
      id: '5',
      nome: 'Maçã',
 
      quantidade: 6,
      unidade: 'unid.',
      validade: '15/01',
      status: 'OK',
      entrarNaIA: true,
    ),
    AlimentoEstoque(
      id: '6',
      nome: 'Cenoura',

      quantidade: 400,
      unidade: 'g',
      validade: '18/01',
      status: 'OK',
      entrarNaIA: true,
    ),
    AlimentoEstoque(
      id: '7',
      nome: 'Ovos',

      quantidade: 12,
      unidade: 'unid.',
      validade: '20/01',
      status: 'OK',
      entrarNaIA: true,
    ),
    AlimentoEstoque(
      id: '8',
      nome: 'Limão',

      quantidade: 8,
      unidade: 'unid.',
      validade: '22/01',
      status: 'OK',
      entrarNaIA: false,
    ),

    AlimentoEstoque(
      id: '9',
      nome: 'Peito de Frango',
    
      quantidade: 600,
      unidade: 'g',
      validade: '22/01',
      status: 'OK',
      entrarNaIA: true,
    ),

    AlimentoEstoque(
      id: '10',
      nome: 'Arroz',

      quantidade: 2,
      unidade: 'kg',
      validade: '22/01',
      status: 'OK',
      entrarNaIA: true,
    ),

    AlimentoEstoque(
      id: '11',
      nome: 'Molho de Tomate',
    
      quantidade: 300,
      unidade: 'g',
      validade: '07/01',
      status: 'Atenção',
      entrarNaIA: true,
    ),

    AlimentoEstoque(
      id: '12',
      nome: 'Presunto',
     
      quantidade: 200,
      unidade: 'g',
      validade: '10/01',
      status: 'Atenção',
      entrarNaIA: false,
    ),

    AlimentoEstoque(
  id: '13',
  nome: 'Macarrão',
  
  quantidade: 500,
  unidade: 'g',
  validade: '30/01',
  status: 'OK',
  entrarNaIA: true,
),

AlimentoEstoque(
  id: '14',
  nome: 'Batata',

  quantidade: 1,
  unidade: 'kg',
  validade: '25/01',
  status: 'OK',
  entrarNaIA: true,
),

AlimentoEstoque(
  id: '15',
  nome: 'Cebola',

  quantidade: 4,
  unidade: 'unid.',
  validade: '28/01',
  status: 'OK',
  entrarNaIA: true,
),

AlimentoEstoque(
  id: '16',
  nome: 'Alho',

  quantidade: 2,
  unidade: 'cabeças',
  validade: '15/02',
  status: 'OK',
  entrarNaIA: true,
),

AlimentoEstoque(
  id: '17',
  nome: 'Tomate',

  quantidade: 5,
  unidade: 'unid.',
  validade: '18/01',
  status: 'OK',
  entrarNaIA: true,
),

AlimentoEstoque(
  id: '18',
  nome: 'Alface',

  quantidade: 1,
  unidade: 'unid.',
  validade: '12/01',
  status: 'Urgente',
  entrarNaIA: true,
),

AlimentoEstoque(
  id: '19',
  nome: 'Banana',

  quantidade: 8,
  unidade: 'unid.',
  validade: '14/01',
  status: 'Urgente',
  entrarNaIA: true,
),

AlimentoEstoque(
  id: '20',
  nome: 'Pão de Forma',

  quantidade: 1,
  unidade: 'pct.',
  validade: '20/01',
  status: 'OK',
  entrarNaIA: true,
),
  ];
}