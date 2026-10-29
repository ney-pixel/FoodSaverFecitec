-- manter historico ao excluir alimento

ALTER TABLE FS_movimentacoes
  ADD COLUMN descricao_alimento VARCHAR(150) NOT NULL DEFAULT '' AFTER alimento_id;

UPDATE FS_movimentacoes m
  JOIN FS_alimentos a ON a.id = m.alimento_id
  SET m.descricao_alimento = a.descricao
  WHERE m.descricao_alimento = '';

ALTER TABLE FS_movimentacoes MODIFY alimento_id INT NULL;

ALTER TABLE FS_movimentacoes DROP FOREIGN KEY FS_movimentacoes_ibfk_2;

ALTER TABLE FS_movimentacoes
  ADD CONSTRAINT FS_movimentacoes_ibfk_2 FOREIGN KEY (alimento_id) REFERENCES FS_alimentos(id) ON DELETE SET NULL;
