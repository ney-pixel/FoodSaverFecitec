-- tabela de quantidade minima

CREATE TABLE IF NOT EXISTS FS_minimos_alimento (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id        INT NOT NULL,
  nome_alimento     VARCHAR(150) NOT NULL,
  unidade_medida    VARCHAR(20) NOT NULL,
  quantidade_minima DECIMAL(10,2) NOT NULL,
  INDEX idx_usuario_nome (usuario_id, nome_alimento),
  FOREIGN KEY (usuario_id) REFERENCES FS_usuarios(id) ON DELETE CASCADE
);
