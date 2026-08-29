-- Receitas geradas por IA que o usuário escolheu favoritar.
--
-- Diferente de FS_biblioteca_receitas (catálogo fixo, compartilhado por
-- todos os usuários), aqui cada linha pertence a UM usuário (tem
-- usuario_id) e só existe porque ele favoritou a receita gerada — a
-- geração em si (ia/gerar_receita.php) não salva nada, só quando o
-- usuário aperta "favoritar" é que a receita é persistida aqui.
--
-- Por isso não precisa de uma tabela de favoritos separada: a própria
-- existência da linha já significa "favoritada". Desfavoritar = apagar
-- a linha (ia/favoritar_receita_ia.php).

CREATE TABLE IF NOT EXISTS FS_receitas_ia (
  id INT NOT NULL AUTO_INCREMENT,
  usuario_id INT NOT NULL,
  titulo VARCHAR(150) NOT NULL,
  descricao TEXT,
  categoria VARCHAR(50) NOT NULL,
  dificuldade VARCHAR(20) NOT NULL,
  tempo_preparo INT NOT NULL,
  porcoes INT NOT NULL,
  calorias INT NOT NULL,
  imagem VARCHAR(255),
  ingredientes TEXT NOT NULL,
  ingredientes_necessarios TEXT NOT NULL,
  modo_preparo TEXT NOT NULL,
  dicas TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY usuario_id (usuario_id),
  CONSTRAINT FS_receitas_ia_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES FS_usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
