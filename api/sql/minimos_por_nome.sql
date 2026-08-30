-- "Quantidade mínima" deixa de ser vinculada a um lote específico
-- (FS_alimentos_minimos.alimento_id) e passa a ser vinculada ao NOME do
-- alimento. Isso resolve dois problemas:
--
--   1) Antes só dava pra definir um mínimo pra algo que já estava no
--      estoque (precisava de um alimento_id existente). Agora o usuário
--      pode definir "sempre manter 1kg de arroz" mesmo sem ter nenhum
--      arroz no estoque no momento.
--   2) Antes, excluir/consumir o lote que tinha o mínimo apagava o
--      mínimo junto (era uma FK com ON DELETE CASCADE). Agora o mínimo
--      é independente dos lotes — continua valendo mesmo depois que o
--      lote específico que o originou não existe mais.
--
-- listar_compras.php passa a somar (com conversão de unidade, quando
-- possível) todos os lotes de FS_alimentos com o mesmo nome (comparação
-- case-insensitive) pra comparar com o mínimo definido aqui.
--
-- A tabela antiga (FS_alimentos_minimos) não é mais usada pelo app —
-- pode ser removida manualmente mais tarde, depois de confirmar que não
-- há mais nada dependendo dela.

CREATE TABLE IF NOT EXISTS FS_minimos_alimento (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id        INT NOT NULL,
  nome_alimento     VARCHAR(150) NOT NULL,
  unidade_medida    VARCHAR(20) NOT NULL,
  quantidade_minima DECIMAL(10,2) NOT NULL,
  INDEX idx_usuario_nome (usuario_id, nome_alimento),
  FOREIGN KEY (usuario_id) REFERENCES FS_usuarios(id) ON DELETE CASCADE
);
