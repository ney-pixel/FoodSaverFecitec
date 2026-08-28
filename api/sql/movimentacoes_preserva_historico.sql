-- Faz com que excluir um alimento do estoque não seja mais bloqueado por
-- ele já ter movimentações (consumo/desperdício) registradas — o que
-- alimenta os relatórios de histórico.
--
-- Antes: FS_movimentacoes.alimento_id tinha ON DELETE RESTRICT, então
-- excluir o alimento falhava se ele já tivesse alguma movimentação.
--
-- Agora: a movimentação guarda o NOME do alimento no momento em que foi
-- registrada (descricao_alimento), então não depende mais da linha em
-- FS_alimentos continuar existindo. O FK vira ON DELETE SET NULL: ao
-- excluir o alimento, alimento_id da movimentação fica NULL, mas a
-- movimentação (e o nome salvo nela) permanece — os relatórios de
-- desperdício/consumo continuam mostrando o histórico certinho.
--
-- (FS_receita_alimentos continua com ON DELETE RESTRICT sem alteração:
-- excluir um alimento vinculado a uma receita do site ainda é bloqueado.)

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
