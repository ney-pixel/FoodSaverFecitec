//receitas pre-definids para demonstraçao apenas

import 'receita.dart';

class BancoReceitas {
  BancoReceitas._();

  static final List<Receita> receitas = [
    Receita(
      id: '1',
      nome: 'Macarrão à Bolonhesa',
      descricao: 'Uma receita clássica, prática e ideal para o almoço em família.',
      categoria: 'Massas',
      dificuldade: 'Fácil',
      tempoPreparo: 35,
      porcoes: 4,
      calorias: 580,
      imagem: 'assets/receitas/macarrao_bolonhesa.jpg',
      ingredientes: [
        '500 g de macarrão',
        '300 g de carne moída',
        '300 g de molho de tomate',
        '1 cebola média',
        '2 dentes de alho',
        '1 colher de sopa de óleo',
        'Sal a gosto',
        'Queijo ralado (opcional)',
      ],
      ingredientesNecessarios: [
        'Macarrão', 'Carne Moída', 'Molho de Tomate', 'Cebola', 'Alho',
      ],
      preparo: [
        'Encha uma panela grande com aproximadamente 2 litros de água e leve ao fogo alto. Quando a água começar a ferver, adicione uma pitada de sal.',
        'Coloque o macarrão na panela e cozinhe pelo tempo indicado na embalagem, mexendo ocasionalmente para evitar que os fios grudem.',
        'Enquanto o macarrão cozinha, descasque a cebola e corte-a em pedaços pequenos. Em seguida, descasque os dentes de alho e amasse-os.',
        'Em outra panela, coloque uma colher de sopa de óleo e aqueça em fogo médio.',
        'Adicione a cebola e o alho e mexa por cerca de 2 minutos, até que a cebola fique levemente transparente.',
        'Acrescente a carne moída e mexa constantemente até que toda a carne perca a cor avermelhada.',
        'Adicione o molho de tomate e misture bem. Deixe cozinhar em fogo baixo por aproximadamente 5 minutos.',
        'Quando o macarrão estiver cozido, escorra a água e misture o molho ou sirva separadamente.',
        'Se desejar, adicione queijo ralado por cima e sirva ainda quente.',
      ],
      dicas: [
        'Sirva acompanhado de uma salada de alface e tomate.',
        'Se preferir um molho mais encorpado, deixe cozinhar por alguns minutos a mais.',
        'O queijo ralado é opcional, mas deixa a receita mais saborosa.',
      ],
    ),

    Receita(
      id: '2',
      nome: 'Omelete de Queijo',
      descricao: 'Rápido, nutritivo e perfeito para qualquer refeição do dia.',
      categoria: 'Ovos',
      dificuldade: 'Fácil',
      tempoPreparo: 10,
      porcoes: 1,
      calorias: 280,
      imagem: 'assets/receitas/omelete_queijo.jpg',
      ingredientes: [
        '3 ovos',
        '50 g de queijo mussarela fatiado',
        '1 pitada de sal',
        '1 pitada de pimenta-do-reino',
        '1 fio de azeite ou manteiga',
      ],
      ingredientesNecessarios: ['Ovos', 'Queijo Mussarela'],
      preparo: [
        'Quebre os ovos em uma tigela e bata levemente com um garfo. Tempere com sal e pimenta.',
        'Aqueça uma frigideira antiaderente em fogo médio e adicione o azeite ou manteiga.',
        'Despeje os ovos batidos e deixe cozinhar sem mexer até que as bordas comecem a firmar.',
        'Distribua o queijo sobre metade da omelete.',
        'Com uma espátula, dobre a omelete ao meio cobrindo o queijo.',
        'Deixe por mais 1 minuto até o queijo derreter e sirva imediatamente.',
      ],
      dicas: [
        'Adicione tomate picado ou cebola refogada para enriquecer o sabor.',
        'Use fogo médio-baixo para a omelete não queimar por fora antes de cozinhar por dentro.',
      ],
    ),

    Receita(
      id: '3',
      nome: 'Frango Grelhado com Cenoura',
      descricao: 'Prato leve e equilibrado, cheio de proteínas e vitaminas.',
      categoria: 'Carnes',
      dificuldade: 'Fácil',
      tempoPreparo: 30,
      porcoes: 2,
      calorias: 350,
      imagem: 'assets/receitas/frango_cenoura.jpg',
      ingredientes: [
        '2 filés de frango',
        '2 cenouras médias',
        '2 dentes de alho',
        'Suco de 1 limão',
        'Sal e pimenta a gosto',
        '1 fio de azeite',
      ],
      ingredientesNecessarios: ['Frango', 'Cenoura', 'Alho', 'Limão'],
      preparo: [
        'Tempere os filés de frango com alho amassado, suco de limão, sal e pimenta. Deixe marinar por 10 minutos.',
        'Descasque as cenouras e corte em rodelas ou palitos.',
        'Aqueça uma frigideira ou grelha em fogo médio-alto com um fio de azeite.',
        'Grelhe o frango por aproximadamente 6-7 minutos de cada lado até dourar.',
        'Na mesma frigideira, refogue as cenouras com um pouco de sal por 5 minutos.',
        'Sirva o frango acompanhado da cenoura refogada.',
      ],
      dicas: [
        'Adicione ervas frescas como salsinha ou tomilho para dar mais aroma.',
        'Sirva com arroz branco ou salada para uma refeição completa.',
      ],
    ),

    Receita(
      id: '4',
      nome: 'Sopa de Batata com Cenoura',
      descricao: 'Sopa cremosa e reconfortante, ideal para dias frios.',
      categoria: 'Sopas',
      dificuldade: 'Fácil',
      tempoPreparo: 40,
      porcoes: 4,
      calorias: 220,
      imagem: 'assets/receitas/sopa_batata.jpg',
      ingredientes: [
        '3 batatas médias',
        '2 cenouras',
        '1 cebola',
        '2 dentes de alho',
        '1 litro de água ou caldo',
        'Sal e pimenta a gosto',
        'Salsinha para finalizar',
      ],
      ingredientesNecessarios: ['Batata', 'Cenoura', 'Cebola', 'Alho'],
      preparo: [
        'Descasque e pique as batatas, cenouras, cebola e alho em pedaços médios.',
        'Em uma panela grande, refogue a cebola e o alho com um fio de azeite até dourar.',
        'Adicione as batatas e cenouras e misture bem.',
        'Cubra com água ou caldo e leve ao fogo alto até ferver.',
        'Reduza o fogo e cozinhe por 20 minutos até os legumes ficarem macios.',
        'Bata tudo com um mixer ou liquidificador até obter um creme liso.',
        'Tempere com sal e pimenta. Finalize com salsinha picada.',
      ],
      dicas: [
        'Acrescente um fio de creme de leite ao servir para uma sopa ainda mais cremosa.',
        'Pode ser armazenada na geladeira por até 3 dias.',
      ],
    ),

    Receita(
      id: '5',
      nome: 'Arroz com Frango',
      descricao: 'Clássico brasileiro que agrada a toda a família.',
      categoria: 'Pratos Principais',
      dificuldade: 'Médio',
      tempoPreparo: 50,
      porcoes: 4,
      calorias: 480,
      imagem: 'assets/receitas/arroz_frango.jpg',
      ingredientes: [
        '400 g de frango (coxa ou peito)',
        '2 xícaras de arroz',
        '1 cebola',
        '3 dentes de alho',
        '2 tomates',
        '4 xícaras de água quente',
        'Sal, pimenta e temperos a gosto',
        '1 fio de óleo',
      ],
      ingredientesNecessarios: ['Frango', 'Arroz', 'Cebola', 'Alho', 'Tomate'],
      preparo: [
        'Tempere o frango com alho, sal e pimenta. Reserve por 10 minutos.',
        'Em uma panela grande, aqueça o óleo e doure o frango de todos os lados.',
        'Retire o frango e, na mesma panela, refogue a cebola e o alho picados.',
        'Adicione o tomate picado e refogue por 2 minutos.',
        'Acrescente o arroz lavado e refogue por 1 minuto.',
        'Retorne o frango à panela, adicione a água quente e sal a gosto.',
        'Cozinhe em fogo médio por 20 minutos até o arroz secar.',
        'Desligue o fogo, tampe e deixe descansar por 5 minutos antes de servir.',
      ],
      dicas: [
        'Use caldo de frango no lugar da água para um sabor mais intenso.',
        'Adicione ervilhas e cenoura picada para deixar o prato mais colorido.',
      ],
    ),

    Receita(
      id: '6',
      nome: 'Salada de Alface e Tomate',
      descricao: 'Salada fresca, simples e nutritiva para acompanhar qualquer prato.',
      categoria: 'Saladas',
      dificuldade: 'Fácil',
      tempoPreparo: 10,
      porcoes: 2,
      calorias: 80,
      imagem: 'assets/receitas/salada_alface.jpg',
      ingredientes: [
        '1 pé de alface',
        '2 tomates médios',
        'Sal a gosto',
        'Azeite a gosto',
        'Suco de limão a gosto',
      ],
      ingredientesNecessarios: ['Alface', 'Tomate', 'Limão'],
      preparo: [
        'Lave bem as folhas de alface em água corrente e deixe escorrer.',
        'Rasgue ou corte as folhas em pedaços médios e coloque em uma saladeira.',
        'Lave os tomates e corte em fatias ou cubos.',
        'Misture tudo, tempere com sal, azeite e suco de limão.',
        'Sirva imediatamente para manter a crocância.',
      ],
      dicas: [
        'Adicione cebola roxa fatiada para um sabor especial.',
        'Tempere na hora de servir para não murchar as folhas.',
      ],
    ),

    Receita(
      id: '7',
      nome: 'Vitamina de Banana com Leite',
      descricao: 'Bebida energética e deliciosa, ótima para o café da manhã.',
      categoria: 'Bebidas',
      dificuldade: 'Fácil',
      tempoPreparo: 5,
      porcoes: 2,
      calorias: 180,
      imagem: 'assets/receitas/vitamina_banana.jpg',
      ingredientes: [
        '2 bananas maduras',
        '300 ml de leite integral',
        '1 colher de sopa de açúcar (opcional)',
        'Canela em pó (opcional)',
      ],
      ingredientesNecessarios: ['Banana', 'Leite Integral'],
      preparo: [
        'Descasque as bananas e corte em pedaços.',
        'Coloque no liquidificador junto com o leite.',
        'Adicione açúcar se desejar e bata por 1 minuto.',
        'Sirva gelado, com canela polvilhada por cima se quiser.',
      ],
      dicas: [
        'Use banana congelada para uma vitamina mais cremosa e gelada.',
        'Substitua o açúcar por mel para uma versão mais natural.',
      ],
    ),

    Receita(
      id: '8',
      nome: 'Peito de Frango Grelhado',
      descricao: 'Proteína magra e saborosa, ideal para dietas e refeições saudáveis.',
      categoria: 'Carnes',
      dificuldade: 'Fácil',
      tempoPreparo: 25,
      porcoes: 2,
      calorias: 290,
      imagem: 'assets/receitas/peito_frango.jpg',
      ingredientes: [
        '2 peitos de frango',
        '2 dentes de alho',
        'Suco de 1 limão',
        'Sal, pimenta e orégano a gosto',
        '1 fio de azeite',
      ],
      ingredientesNecessarios: ['Peito de Frango', 'Alho', 'Limão'],
      preparo: [
        'Faça cortes superficiais no frango para o tempero penetrar melhor.',
        'Tempere com alho amassado, limão, sal, pimenta e orégano.',
        'Deixe marinar por pelo menos 15 minutos.',
        'Aqueça uma grelha ou frigideira em fogo médio-alto com azeite.',
        'Grelhe por 7 minutos de cada lado até dourar e cozinhar completamente.',
        'Sirva com salada ou legumes grelhados.',
      ],
      dicas: [
        'Para verificar se está cozido, corte a parte mais grossa: a carne deve estar branca por dentro.',
        'Deixar marinar de um dia para o outro na geladeira intensifica o sabor.',
      ],
    ),

    Receita(
      id: '9',
      nome: 'Torrada com Presunto e Queijo',
      descricao: 'Lanche rápido e saboroso para qualquer hora do dia.',
      categoria: 'Lanches',
      dificuldade: 'Fácil',
      tempoPreparo: 10,
      porcoes: 1,
      calorias: 320,
      imagem: 'assets/receitas/torrada_presunto.jpg',
      ingredientes: [
        '2 fatias de pão de forma',
        '2 fatias de presunto',
        '2 fatias de queijo mussarela',
        'Manteiga (opcional)',
      ],
      ingredientesNecessarios: ['Pão de Forma', 'Presunto', 'Queijo Mussarela'],
      preparo: [
        'Torre as fatias de pão na torradeira ou frigideira.',
        'Monte o lanche com presunto e queijo sobre o pão tostado.',
        'Se quiser uma versão quente, leve ao microondas por 30 segundos ou à frigideira com manteiga até derreter o queijo.',
        'Sirva imediatamente.',
      ],
      dicas: [
        'Adicione tomate fatiado e alface para um lanche mais completo.',
        'Use mostarda ou maionese para dar mais sabor.',
      ],
    ),

    Receita(
      id: '10',
      nome: 'Molho de Tomate Caseiro',
      descricao: 'Molho versátil e saboroso para massas, pizzas ou carnes.',
      categoria: 'Molhos',
      dificuldade: 'Fácil',
      tempoPreparo: 20,
      porcoes: 4,
      calorias: 90,
      imagem: 'assets/receitas/molho_tomate.jpg',
      ingredientes: [
        '5 tomates maduros',
        '1 cebola',
        '3 dentes de alho',
        '1 fio de azeite',
        'Sal, açúcar e manjericão a gosto',
      ],
      ingredientesNecessarios: ['Tomate', 'Cebola', 'Alho'],
      preparo: [
        'Escalde os tomates em água fervente por 1 minuto, retire a pele e as sementes.',
        'Pique a cebola e o alho finamente.',
        'Refogue a cebola e o alho no azeite até dourar.',
        'Adicione os tomates picados e cozinhe em fogo médio por 10-15 minutos.',
        'Tempere com sal, uma pitada de açúcar e manjericão.',
        'Bata no liquidificador para um molho mais liso, se preferir.',
      ],
      dicas: [
        'Adicione uma folha de louro durante o cozimento para um aroma especial.',
        'Pode ser armazenado na geladeira por até 5 dias ou congelado por 3 meses.',
      ],
    ),
  ];

  //busca a receita e so retorna se todos os ingredientes estiverem selecionados
  static List<Receita> buscarPorIngredientes(List<String> nomesSelecionados) {
    final selecionadosLower =
        nomesSelecionados.map((n) => n.toLowerCase()).toList();

    return receitas.where((r) {
      return r.ingredientesNecessarios.every(
        (necessario) => selecionadosLower
            .any((sel) => sel.contains(necessario.toLowerCase()) ||
                necessario.toLowerCase().contains(sel)),
      );
    }).toList();
  }
}