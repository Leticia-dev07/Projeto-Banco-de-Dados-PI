use distribuicao_de_sementes;

-- Relatório de pedidos agrupados por mês e ano.

select 
	YEAR(p.dataPedido) AS ANO,
    MONTH(p.dataPedido) AS MÊS,
    COUNT(*) AS Total_de_Pedidos,
    CONCAT("R$", format(SUM(ip.quantPedida * ip.precoUnitario), 2,'de_DE')) as Valor_Total
	from pedido p
		join itemPedido ip on p.idPedido = ip.Pedido_idPedido
		group by year (p.dataPedido), month(p.dataPedido)
		order by ANO,MÊS;
    
--  Exibe a quantidade disponível e saída de estoque em cada armazém, com sua localização.

SELECT 
    a.nome AS 'Armazém',
    l.nome AS 'Localização',
    e.quantDisponivel,
    e.quantSaida
FROM Estoque e
JOIN Estoque_has_Armazem ea
    ON e.idEstoque = ea.Estoque_idEstoque
JOIN Armazem a
    ON a.idArmazem = ea.Armazem_idArmazem
    AND a.Distribuidor_idDistribuidor = ea.Armazem_Distribuidor_idDistribuidor
JOIN Localizacao l
    ON l.idLocalizacao = a.Localizacao_idLocalizacao
ORDER BY a.nome;

    
--  Mostra fornecedores que forneceram volume de sementes acima da média.  
SELECT 
    f.nome AS Nome, 
    SUM(l.quantReceb) AS Total_Sementes_Fornecidas
FROM Fornecedor f
JOIN Lote l 
    ON f.idFornecedor = l.Fornecedor_idFornecedor
GROUP BY f.nome
HAVING 
    SUM(l.quantReceb) > (
        SELECT AVG(total) 
        FROM (
            SELECT SUM(quantReceb) AS total 
            FROM Lote 
            GROUP BY Fornecedor_idFornecedor
        ) AS media
    )
ORDER BY Total_Sementes_Fornecidas DESC;

--  Mostra os clientes que têm pedidos com status “Pendente”, ordenados por data do pedido.

	select 
		c.nome as 'Nome',
        c.tipo as 'Tipo',
        date_format(p.dataPedido, "%d/%m/%y") as Data_Pedido,
        p.status as 'Status'
		from Cliente C
			join Cliente_Has_Pedido cp on c.idCliente = cp.Cliente_idCliente
            join Pedido p on cp.Pedido_idPedido = p.idPedido
				where p.status = 'Pendente'
				order by p.dataPedido;


-- Agrupa sementes por origem (nacional/importado) mostrando quantidades.

select
	s.origem as 'Origem',
    count(*) as 'Quantidade Sementes',
    sum(l.quantReceb) as 'Total de sementes'
		from Sementes s
			join Lote l on s.idSementes = l.Sementes_idSementes
			group by s.origem
			order by 'Total de sementes' desc;
		
    
-- 6 Sementes com maior giro (mais saídas) no estoque
SELECT 
    s.nomeCientifico AS Semente,
    SUM(e.quantSaida) AS Total_Saida
FROM Estoque e
JOIN Lote l 
    ON e.idEstoque = l.Estoque_idEstoque
JOIN Sementes s 
    ON s.idSementes = l.Sementes_idSementes
GROUP BY s.nomeCientifico
ORDER BY Total_Saida DESC;

DESC Estoque;
DESC Sementes;

-- 7 Para descobrir qual armazém tem maior quantidade disponível
SELECT 
    a.nome AS Armazem,
    SUM(e.quantDisponivel) AS Total_Disponivel
FROM Estoque e
JOIN estoque_has_armazem ea ON ea.Estoque_idEstoque = e.idEstoque
JOIN Armazem a ON a.idArmazem = ea.Armazem_idArmazem
GROUP BY a.nome
ORDER BY Total_Disponivel DESC;

-- 8 Clientes com seus Endereços e Telefones
SELECT 
    c.idCliente,
    c.nome,
    c.CPF,
    c.CNPJ,
    c.tipo,
    t.numero AS telefone,
    e.rua,
    e.numero,
    e.bairro,
    e.cidade,
    e.UF,
    e.CEP
FROM Cliente c
INNER JOIN Telefone t ON c.Telefone_idTelefone = t.idTelefone
INNER JOIN Endereco e ON c.Endereco_idEndereco = e.idEndereco;

--  9 Pedidos com detalhes completos
SELECT 
    p.idPedido,
    p.dataPedido,
    p.status,
    c.nome AS nome_cliente,
    c.CPF AS cpf_cliente,
    c.CNPJ AS cnpj_cliente,
    ip.quantPedida,
    ip.precoUnitario,
    s.nomeComum AS nome_semente,
    s.nomeCientifico,
    f.nome AS nome_fornecedor
FROM Pedido p
INNER JOIN Cliente_has_Pedido chp ON p.idPedido = chp.Pedido_idPedido
INNER JOIN Cliente c ON chp.Cliente_idCliente = c.idCliente
INNER JOIN itemPedido ip ON p.idPedido = ip.Pedido_idPedido
INNER JOIN Lote l ON ip.Lote_idLote = l.idLote
INNER JOIN Sementes s ON l.Sementes_idSementes = s.idSementes
INNER JOIN Fornecedor f ON l.Fornecedor_idFornecedor = f.idFornecedor;

-- 10  Clientes que Mais Compraram (Top 10)
 SELECT 
    c.nome AS Cliente,
    c.tipo AS 'Tipo Cliente',
    COUNT(DISTINCT p.idPedido) AS 'Total de Pedidos',
    SUM(ip.quantPedida) AS 'Total de Sementes Compradas',
    CONCAT('R$ ', FORMAT(SUM(ip.quantPedida * CAST(ip.precoUnitario AS DECIMAL(10,2))), 2, 'de_DE')) AS 'Valor Total Gasto'
FROM Cliente c
JOIN Cliente_has_Pedido cp ON c.idCliente = cp.Cliente_idCliente
JOIN Pedido p ON cp.Pedido_idPedido = p.idPedido
JOIN itemPedido ip ON p.idPedido = ip.Pedido_idPedido
GROUP BY c.idCliente, c.nome, c.tipo
ORDER BY SUM(ip.quantPedida * CAST(ip.precoUnitario AS DECIMAL(10,2))) DESC
LIMIT 10;

-- 11  Armazéns com Capacidade Ociosa
SELECT 
    a.nome AS Armazém,
    a.capacMax AS 'Capacidade Máxima',
    SUM(e.quantDisponivel) AS 'Estoque Atual',
    (a.capacMax - SUM(e.quantDisponivel)) AS 'Capacidade Livre',
    CONCAT(FORMAT((SUM(e.quantDisponivel) / a.capacMax) * 100, 1), '%') AS 'Taxa de Ocupação'
FROM Armazem a
JOIN Estoque_has_Armazem ea ON a.idArmazem = ea.Armazem_idArmazem
JOIN Estoque e ON ea.Estoque_idEstoque = e.idEstoque
GROUP BY a.idArmazem, a.nome, a.capacMax
HAVING (SUM(e.quantDisponivel) / a.capacMax) < 0.7
ORDER BY (SUM(e.quantDisponivel) / a.capacMax) ASC;

-- 12 Fornecedores por Região (Baseado no CEP)
SELECT 
    SUBSTRING(e.CEP, 1, 5) AS 'Região CEP',
    COUNT(DISTINCT f.idFornecedor) AS 'Total de Fornecedores',
    GROUP_CONCAT(DISTINCT f.nome SEPARATOR ', ') AS 'Fornecedores',
    SUM(l.quantReceb) AS 'Total de Sementes Fornecidas',
    CONCAT('R$ ', FORMAT(SUM(l.quantReceb * l.precUnit), 2, 'de_DE')) AS 'Valor Total'
FROM Fornecedor f
JOIN Lote l ON f.idFornecedor = l.Fornecedor_idFornecedor
JOIN Cliente c ON f.idFornecedor = c.idCliente
JOIN Endereco e ON c.Endereco_idEndereco = e.idEndereco
GROUP BY SUBSTRING(e.CEP, 1, 5)
ORDER BY SUM(l.quantReceb) DESC;

-- 13 Análise de Rentabilidade por Semente
SELECT 
    s.nomeComum AS 'Semente',
    s.origem AS 'Origem',
    SUM(e.quantSaida) AS 'Total Vendido',
    SUM(e.quantDisponivel) AS 'Em Estoque',
    CONCAT('R$ ', FORMAT(AVG(l.precUnit), 2, 'de_DE')) AS 'Custo Médio',
    CONCAT('R$ ', FORMAT(
        (SELECT AVG(CAST(ip.precoUnitario AS DECIMAL(10,2))) 
         FROM itemPedido ip 
         JOIN Lote l2 ON ip.Lote_idLote = l2.idLote 
         WHERE l2.Sementes_idSementes = s.idSementes), 2, 'de_DE'
    )) AS 'Preço Médio Venda',
    CONCAT(
        FORMAT(
            ((SELECT AVG(CAST(ip.precoUnitario AS DECIMAL(10,2))) 
              FROM itemPedido ip 
              JOIN Lote l2 ON ip.Lote_idLote = l2.idLote 
              WHERE l2.Sementes_idSementes = s.idSementes) - AVG(l.precUnit)) / AVG(l.precUnit) * 100, 
            1
        ), '%'
    ) AS 'Margem Lucro %'
FROM Sementes s
JOIN Lote l ON s.idSementes = l.Sementes_idSementes
JOIN Estoque e ON l.Estoque_idEstoque = e.idEstoque
GROUP BY s.idSementes, s.nomeComum, s.origem
ORDER BY ((SELECT AVG(CAST(ip.precoUnitario AS DECIMAL(10,2))) 
           FROM itemPedido ip 
           JOIN Lote l2 ON ip.Lote_idLote = l2.idLote 
           WHERE l2.Sementes_idSementes = s.idSementes) - AVG(l.precUnit)) / AVG(l.precUnit) DESC;

-- 14  Quantidade de Saída de Estoque para Sementes Nacionais:
-- Soma a quantidade de saída (quantSaida) de todos os estoques associados a sementes de origem 'Nacional' 
-- (usando Subquery no FROM ou SELECT).

select SUM(e.quantSaida) as TotalSaidaNacional 
	from Estoque e 	
		where e.idEstoque in 
        (select l.Estoque_idEstoque 
			from Lote l 
            join Sementes s on l.Sementes_idSementes = s.idSementes 
            where s.origem = 'Nacional');
            
-- 15  Sementes e Seus Lotes Recebidos Antes de Março de 2024:
-- Exibe o nome comum da semente e a data de aquisição do lote correspondente, filtrando por lotes adquiridos antes de '2024-03-01'.

SELECT s.nomeComum, l.dataAquisic 
	FROM Sementes s 
		JOIN Lote l ON s.idSementes = l.Sementes_idSementes 
		WHERE l.dataAquisic < '2024-03-01';     
        
 
-- 16  Identifica pedidos com valor acima da média, segmentados por tipo de cliente (pessoa física ou jurídica), útil para análise de clientes premium.

select 
    c.nome as 'Cliente',
    c.tipo as 'Tipo',
    p.idPedido as 'Pedido',
    CONCAT('R$',(format(SUM(ip.quantPedida * ip.precoUnitario), 2,'de_DE'))) as 'Valor Total',
    (SELECT AVG(total) 
     from (
         select SUM(quantPedida * precoUnitario) AS total
         from itemPedido
         group by Pedido_idPedido
     ) as media) as 'Média Geral'
from 
    Cliente c
		join Cliente_has_Pedido cp ON c.idCliente = cp.Cliente_idCliente
        join Pedido p ON cp.Pedido_idPedido = p.idPedido
		join itemPedido ip ON p.idPedido = ip.Pedido_idPedido
        group by c.nome, c.tipo, p.idPedido
having 
    SUM(ip.quantPedida * ip.precoUnitario) > (
        SELECT AVG(total) 
        from (
            select SUM(quantPedida * precoUnitario) as total
            from itemPedido
            group by Pedido_idPedido
        ) as media
    )
order by 
    c.tipo, SUM(ip.quantPedida * ip.precoUnitario) desc;
    
    
-- 17 Identifica armazéns com menos de 50% de capacidade utilizada, permitindo otimizar a distribuição de estoque entre unidades.

select 
    a.nome AS 'Armazém',
    a.capacMax AS 'Capacidade Máxima',
    e.quantDisponivel AS 'Estoque Atual',
    ROUND((e.quantDisponivel / a.capacMax) * 100, 2) AS 'Percentual Ocupado',
    loc.nome AS 'Localização'
from Armazem a
		join Estoque_has_Armazem ea on a.idArmazem = ea.Armazem_idArmazem
		join Estoque e on ea.Estoque_idEstoque = e.idEstoque
		join Localizacao loc on a.Localizacao_idLocalizacao = loc.idLocalizacao
			WHERE (e.quantDisponivel / a.capacMax) < 0.5
				order by (e.quantDisponivel / a.capacMax) asc;   
                
                
-- 18 Fornece um histórico completo de compras por cliente, incluindo ticket médio, útil para estratégias de fidelização.

SELECT 
    c.nome as 'Cliente',
    c.tipo as 'Tipo',
    COUNT(distinct p.idPedido) as 'Total de Pedidos',
    SUM(ip.quantPedida) AS 'Total de Itens Comprados',
    CONCAT('R$ ', format(SUM(ip.quantPedida * ip.precoUnitario), 2)) AS 'Valor Total Gasto',
    CONCAT('R$ ', format(SUM(ip.quantPedida * ip.precoUnitario) / COUNT(DISTINCT p.idPedido), 2)) AS 'Ticket Médio'
		from Cliente c
		join Cliente_has_Pedido cp on c.idCliente = cp.Cliente_idCliente
		join Pedido p on cp.Pedido_idPedido = p.idPedido
		join itemPedido ip on p.idPedido = ip.Pedido_idPedido
			group by c.nome, c.tipo
			order by SUM(ip.quantPedida * ip.precoUnitario) DESC;                
                
-- 19 Análise de Sazonalidade de Pedidos por Tipo de Cliente
-- Identifica padrões sazonais de compra por tipo de cliente (PF/PJ)
SELECT 
    MONTH(p.dataPedido) AS 'Mês',
    YEAR(p.dataPedido) AS 'Ano',
    c.tipo AS 'Tipo Cliente',
    COUNT(DISTINCT p.idPedido) AS 'Total Pedidos',
    SUM(ip.quantPedida) AS 'Total Sementes Vendidas',
    CONCAT('R$ ', FORMAT(SUM(ip.quantPedida * CAST(ip.precoUnitario AS DECIMAL(10,2))), 2)) AS 'Faturamento',
    CONCAT(FORMAT(
        (SUM(ip.quantPedida) / LAG(SUM(ip.quantPedida)) OVER (PARTITION BY c.tipo ORDER BY YEAR(p.dataPedido), MONTH(p.dataPedido)) - 1) * 100, 
        1
    ), '%') AS 'Crescimento vs Mês Anterior'
FROM Cliente c
JOIN Cliente_has_Pedido cp ON c.idCliente = cp.Cliente_idCliente
JOIN Pedido p ON cp.Pedido_idPedido = p.idPedido
JOIN itemPedido ip ON p.idPedido = ip.Pedido_idPedido
WHERE p.dataPedido >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY YEAR(p.dataPedido), MONTH(p.dataPedido), c.tipo
ORDER BY c.tipo, YEAR(p.dataPedido) DESC, MONTH(p.dataPedido) DESC;
            
-- 20  Análise de Performance de Fornecedores por Qualidade de Sementes
-- Avalia fornecedores baseado na taxa de rotatividade e validade dos lotes
-- NULLIF função do SQL que retorna NULL se duas expressões forem iguais, caso contrário retorna o valor da primeira expressão.
SELECT 
    f.nome AS 'Fornecedor',
    f.CNPJ,
    COUNT(DISTINCT l.idLote) AS 'Total de Lotes',
    SUM(l.quantReceb) AS 'Total Sementes Fornecidas',
    CONCAT('R$ ', FORMAT(AVG(l.precUnit), 2)) AS 'Preço Médio Unitário',
    
    -- Taxa de rotatividade (saída/disponível)
    CONCAT(FORMAT(
        (SELECT SUM(e.quantSaida) 
         FROM Estoque e 
         JOIN Lote l2 ON e.idEstoque = l2.Estoque_idEstoque 
         WHERE l2.Fornecedor_idFornecedor = f.idFornecedor) /
        NULLIF((SELECT SUM(e.quantDisponivel) 
                FROM Estoque e 
                JOIN Lote l2 ON e.idEstoque = l2.Estoque_idEstoque 
                WHERE l2.Fornecedor_idFornecedor = f.idFornecedor), 0) * 100, 
        1
    ), '%') AS 'Taxa de Rotatividade',
    
    -- Lotes próximos do vencimento (menos de 30 dias)
    SUM(CASE WHEN l.dataValid BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS 'Lotes Próximos Vencer',
    
    -- Classificação de performance
    CASE 
        WHEN AVG(l.precUnit) < (SELECT AVG(precUnit) FROM Lote) 
             AND (SELECT SUM(e.quantSaida) FROM Estoque e JOIN Lote l2 ON e.idEstoque = l2.Estoque_idEstoque WHERE l2.Fornecedor_idFornecedor = f.idFornecedor) / 
                 NULLIF((SELECT SUM(e.quantDisponivel) FROM Estoque e JOIN Lote l2 ON e.idEstoque = l2.Estoque_idEstoque WHERE l2.Fornecedor_idFornecedor = f.idFornecedor), 0) > 0.7 
        THEN '⭐ Excelente'
        WHEN AVG(l.precUnit) < (SELECT AVG(precUnit) FROM Lote) 
             AND (SELECT SUM(e.quantSaida) FROM Estoque e JOIN Lote l2 ON e.idEstoque = l2.Estoque_idEstoque WHERE l2.Fornecedor_idFornecedor = f.idFornecedor) / 
                 NULLIF((SELECT SUM(e.quantDisponivel) FROM Estoque e JOIN Lote l2 ON e.idEstoque = l2.Estoque_idEstoque WHERE l2.Fornecedor_idFornecedor = f.idFornecedor), 0) > 0.4 
        THEN ' Bom'
        ELSE ' Revisar'
    END AS 'Performance'

FROM Fornecedor f
JOIN Lote l ON f.idFornecedor = l.Fornecedor_idFornecedor
LEFT JOIN Estoque e ON l.Estoque_idEstoque = e.idEstoque
GROUP BY f.idFornecedor, f.nome, f.CNPJ
HAVING COUNT(DISTINCT l.idLote) > 0
ORDER BY 
    (SELECT SUM(e.quantSaida) FROM Estoque e JOIN Lote l2 ON e.idEstoque = l2.Estoque_idEstoque WHERE l2.Fornecedor_idFornecedor = f.idFornecedor) /
    NULLIF((SELECT SUM(e.quantDisponivel) FROM Estoque e JOIN Lote l2 ON e.idEstoque = l2.Estoque_idEstoque WHERE l2.Fornecedor_idFornecedor = f.idFornecedor), 0) DESC;