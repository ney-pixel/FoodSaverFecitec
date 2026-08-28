-- Biblioteca de receitas do app mobile: catálogo fixo/imutável mantido
-- pelos desenvolvedores (não confundir com FS_receitas, que é a feature
-- "Minhas Receitas" do site, onde o próprio usuário cadastra as dele).
--
-- Estrutura própria e independente de FS_receitas/FS_grupos_receitas —
-- nada aqui altera ou depende do que o site já usa.

CREATE TABLE IF NOT EXISTS FS_biblioteca_receitas (
  id INT NOT NULL AUTO_INCREMENT,
  titulo VARCHAR(150) NOT NULL,
  descricao TEXT,
  categoria VARCHAR(50) NOT NULL,
  dificuldade VARCHAR(20) NOT NULL,
  tempo_preparo INT NOT NULL,
  porcoes INT NOT NULL,
  calorias INT NOT NULL,
  imagem VARCHAR(255),
  ingredientes TEXT NOT NULL,               -- itens com medida, separados por '||'
  ingredientes_necessarios TEXT NOT NULL,   -- nomes simples usados no "match" com o estoque, separados por '||'
  modo_preparo TEXT NOT NULL,               -- passos do preparo, separados por '||'
  dicas TEXT,                               -- dicas, separadas por '||'
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS FS_biblioteca_favoritos (
  usuario_id INT NOT NULL,
  receita_id INT NOT NULL,
  PRIMARY KEY (usuario_id, receita_id),
  KEY receita_id (receita_id),
  CONSTRAINT FS_biblioteca_favoritos_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES FS_usuarios(id) ON DELETE CASCADE,
  CONSTRAINT FS_biblioteca_favoritos_ibfk_2 FOREIGN KEY (receita_id) REFERENCES FS_biblioteca_receitas(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS FS_grupos_biblioteca (
  id INT NOT NULL AUTO_INCREMENT,
  usuario_id INT NOT NULL,
  nome VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  KEY usuario_id (usuario_id),
  CONSTRAINT FS_grupos_biblioteca_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES FS_usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS FS_grupo_biblioteca (
  grupo_id INT NOT NULL,
  receita_id INT NOT NULL,
  PRIMARY KEY (grupo_id, receita_id),
  KEY receita_id (receita_id),
  CONSTRAINT FS_grupo_biblioteca_ibfk_1 FOREIGN KEY (grupo_id) REFERENCES FS_grupos_biblioteca(id) ON DELETE CASCADE,
  CONSTRAINT FS_grupo_biblioteca_ibfk_2 FOREIGN KEY (receita_id) REFERENCES FS_biblioteca_receitas(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
