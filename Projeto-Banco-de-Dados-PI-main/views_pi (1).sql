-- views
USE distribuicao_de_sementes;

-- 1 Quantidade disponível e saída por armazém e localização
CREATE VIEW vw_estoque_por_armazem AS
SELECT 
    a.nome AS Armazem,
    l.nome AS Localizacao,
    e.quantDisponivel,
    e.quantSaida
FROM Estoque e
JOIN Estoque_has_Armazem ea ON e.idEstoque = ea.Estoque_idEstoque
JOIN Armazem a ON a.idArmazem = ea.Armazem_idArmazem
    AND a.Distribuidor_idDistribuidor = ea.Armazem_Distribuidor_idDistribuidor
JOIN Localizacao l ON l.idLocalizacao = a.Localizacao_idLocalizacao;

-- 2 Total de sementes fornecidas por fornecedor
CREATE VIEW vw_total_sementes_por_fornecedor AS
SELECT 
    f.nome AS Fornecedor,
    SUM(l.quantReceb) AS TotalSementes
FROM Fornecedor f
JOIN Lote l ON f.idFornecedor = l.Fornecedor_idFornecedor
GROUP BY f.nome;

-- 3️ Fornecedores acima da média de fornecimento
CREATE VIEW vw_fornecedores_acima_media AS
SELECT 
    f.nome AS Fornecedor,
    SUM(l.quantReceb) AS TotalSementes
FROM Fornecedor f
JOIN Lote l ON f.idFornecedor = l.Fornecedor_idFornecedor
GROUP BY f.nome
HAVING SUM(l.quantReceb) > (
    SELECT AVG(total)
    FROM (
        SELECT SUM(quantReceb) AS total 
        FROM Lote 
        GROUP BY Fornecedor_idFornecedor
    ) AS media
);

-- 4️ Informações dos lotes + estoque + semente
CREATE VIEW vw_lotes_detalhados AS
SELECT 
    lt.idLote,
    st.quantDisponivel,
    st.quantSaida,
    s.nomeComum,
    lt.quantReceb,
    lt.dataValid
FROM Lote lt
JOIN Estoque st ON lt.Estoque_idEstoque = st.idEstoque
JOIN Sementes s ON lt.Sementes_idSementes = s.idSementes;

-- 5 Estoque total por distribuidor
CREATE VIEW vw_estoque_por_distribuidor AS
SELECT 
    d.localEntrega AS LocalEntrega,
    SUM(e.quantDisponivel) AS TotalDisponivel
FROM Estoque_has_Armazem ea
JOIN Armazem a ON ea.Armazem_idArmazem = a.idArmazem
    AND ea.Armazem_Distribuidor_idDistribuidor = a.Distribuidor_idDistribuidor
JOIN Distribuidor d ON a.Distribuidor_idDistribuidor = d.idDistribuidor
JOIN Estoque e ON ea.Estoque_idEstoque = e.idEstoque
GROUP BY d.localEntrega;

-- 6 Quantidade de pedidos por cliente
CREATE VIEW vw_pedidos_por_cliente AS
SELECT 
    c.nome AS Cliente,
    COUNT(cp.Pedido_idPedido) AS TotalPedidos
FROM Cliente c
LEFT JOIN Cliente_has_Pedido cp ON c.idCliente = cp.Cliente_idCliente
GROUP BY c.nome;

-- 7 Itens pedidos com valor total
CREATE VIEW vw_itens_pedidos AS
SELECT 
    ip.iditemPedido,
    ip.quantPedida,
    ip.precoUnitario,
    (ip.quantPedida * ip.precoUnitario) AS TotalItem
FROM itemPedido ip;

-- 8 Pedidos com status e data
CREATE VIEW vw_pedidos_detalhados AS
SELECT 
    p.idPedido,
    p.dataPedido,
    p.status,
    c.nome AS Cliente
FROM Pedido p
JOIN Cliente_has_Pedido cp ON p.idPedido = cp.Pedido_idPedido
JOIN Cliente c ON c.idCliente = cp.Cliente_idCliente;

-- 9 Sementes por distribuidor
CREATE VIEW vw_sementes_por_distribuidor AS
SELECT 
    d.idDistribuidor,
    d.localEntrega,
    COUNT(s.idSementes) AS TotalSementes
FROM Distribuidor d
LEFT JOIN Sementes s ON d.idDistribuidor = s.Distribuidor_idDistribuidor
GROUP BY d.idDistribuidor, d.localEntrega;

-- 10 Estoque total geral
CREATE VIEW vw_total_estoque AS
SELECT 
    SUM(quantDisponivel) AS TotalDisponivel,
    SUM(quantSaida) AS TotalSaida
FROM Estoque;

-- 1. Quantidade disponível e saída por armazém e localização
SELECT * FROM vw_estoque_por_armazem;

-- 2. Total de sementes fornecidas por fornecedor
SELECT * FROM vw_total_sementes_por_fornecedor;

-- 3. Fornecedores acima da média de fornecimento
SELECT * FROM vw_fornecedores_acima_media;

-- 4. Informações dos lotes + estoque + semente
SELECT * FROM vw_lotes_detalhados;

-- 5. Estoque total por distribuidor
SELECT * FROM vw_estoque_por_distribuidor;

-- 6. Quantidade de pedidos por cliente
SELECT * FROM vw_pedidos_por_cliente;

-- 7. Itens pedidos com valor total
SELECT * FROM vw_itens_pedidos;

-- 8. Pedidos com status e data
SELECT * FROM vw_pedidos_detalhados;

-- 9. Sementes por distribuidor
SELECT * FROM vw_sementes_por_distribuidor;

-- 10. Estoque total geral
SELECT * FROM vw_total_estoque;
