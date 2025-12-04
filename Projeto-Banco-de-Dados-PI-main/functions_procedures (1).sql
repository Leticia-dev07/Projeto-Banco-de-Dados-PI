-- Criações das funções do banco

-- 1 Função para Verificar Validade de Lotes
delimiter $$
create function verificar_lotes_vencidos(data_consulta DATE)
returns int 
READS SQL DATA
begin 
	declare total_lotes_vencidos int;
    SELECT COUNT(*) INTO total_lotes_vencidos
    FROM Lote 
    WHERE dataValid < data_consulta;
	RETURN total_lotes_vencidos;
end $$
delimiter ;
-- Verificar lotes vencidos até hoje
SELECT verificar_lotes_vencidos(CURDATE()) AS lotes_vencidos;
-- Verificar lotes que vencerão em 30 dias
SELECT verificar_lotes_vencidos(DATE_ADD(CURDATE(), INTERVAL 30 DAY)) AS lotes_a_vencer;

-- 2 Função para Calcular Capacidade de Armazenamento
delimiter $$
create function calcular_capacidade_armazem(armazem_id INT)
returns decimal(5,2)
READS SQL DATA
begin
    declare capacidade_total INT;
    declare estoque_atual INT;
    declare percentual_ocupacao DECIMAL(5,2);
    
    -- Obter capacidade máxima do armazém
    SELECT capacMax INTO capacidade_total
    FROM Armazem 
    WHERE idArmazem = armazem_id;
    
    -- Calcula o estoque atual no armazém
    SELECT SUM(e.quantDisponivel) INTO estoque_atual
    FROM Estoque e
    INNER JOIN Estoque_has_Armazem eha ON e.idEstoque = eha.Estoque_idEstoque
    WHERE eha.Armazem_idArmazem = armazem_id;
    
    -- Calcula o percentual de ocupação
    IF capacidade_total > 0 THEN
        SET percentual_ocupacao = (estoque_atual / capacidade_total) * 100;
    ELSE
        SET percentual_ocupacao = 0;
    END IF;
    
    RETURN percentual_ocupacao;
end $$
delimiter ;
-- Verifica a ocupação do armazém 1
SELECT calcular_capacidade_armazem(1) AS ocupacao_percentual;
-- Lista a ocupação de todos os armazéns
SELECT idArmazem, nome, calcular_capacidade_armazem(idArmazem) AS ocupacao_percentual
FROM Armazem;

-- 3 Função para Calcular Valor Total do Pedido
delimiter $$
create function calcular_total_pedido(pedido_id INT)
RETURNS decimal(10,2)
READS SQL DATA
begin
    declare total_pedido DECIMAL(10,2);
    
    SELECT SUM(ip.quantPedida * l.precUnit) INTO total_pedido
    FROM itemPedido ip
    INNER JOIN Lote l ON ip.Lote_idLote = l.idLote
    WHERE ip.Pedido_idPedido = pedido_id;
    
    RETURN IFNULL(total_pedido, 0);
end $$
delimiter ; 
-- Ver todos os pedidos e seus totais
SELECT 
    p.idPedido,
    p.dataPedido,
    p.status,
    calcular_total_pedido(p.idPedido) AS valor_total
FROM Pedido p
ORDER BY valor_total DESC;
-- Detalhado com informações do cliente
SELECT 
    p.idPedido,
    p.dataPedido,
    c.nome AS cliente,
    calcular_total_pedido(p.idPedido) AS valor_total
FROM Pedido p
INNER JOIN Cliente_has_Pedido chp ON p.idPedido = chp.Pedido_idPedido
INNER JOIN Cliente c ON chp.Cliente_idCliente = c.idCliente
WHERE calcular_total_pedido(p.idPedido) > 0;

-- 4 Verificar Sementes por Tipo de Cliente
delimiter $$
create function recomendar_semente_cliente(cliente_id INT)
returns VARCHAR(100)
READS SQL DATA
begin
    declare tipo_cliente VARCHAR(45);
    declare recomendacao VARCHAR(100);
    
    SELECT c.tipo INTO tipo_cliente
    FROM Cliente c WHERE c.idCliente = cliente_id;
    
    CASE 
        WHEN tipo_cliente = 'Agricultor' THEN SET recomendacao = 'Sementes de grãos e cereais';
        WHEN tipo_cliente = 'Jardineiro' THEN SET recomendacao = 'Sementes ornamentais e flores';
        WHEN tipo_cliente = 'Produtor Rural' THEN SET recomendacao = 'Sementes para larga escala';
        WHEN tipo_cliente = 'Research' THEN SET recomendacao = 'Sementes para pesquisa';
        ELSE SET recomendacao = 'Sementes diversificadas';
    END CASE;
    
    return recomendacao;
end $$
delimiter ; 

-- 5 Calcular Estoque Mínimo Crítico
delimiter $$
create function  verificar_estoque_critico(estoque_id INT)
returns VARCHAR(20)
READS SQL DATA
begin
    declare quant_atual INT;
    declare status_estoque VARCHAR(20);
    
    SELECT quantDisponivel INTO quant_atual
    FROM Estoque WHERE idEstoque = estoque_id;
    
    IF quant_atual <= 10 THEN
        SET status_estoque = 'CRÍTICO';
    ELSEIF quant_atual <= 50 THEN
        SET status_estoque = 'ALERTA';
    ELSE
        SET status_estoque = 'NORMAL';
    END IF;
    
    return status_estoque;
end $$
delimiter ;
-- teste novamente
SELECT idEstoque, quantDisponivel, verificar_estoque_critico(idEstoque) AS status
FROM Estoque;

-- 6 Calcular Distância Entre Localizações (Simulada)
delimiter $$
create function calcular_distancia_simulada(loc1_id INT, loc2_id INT)
returns DECIMAL(10,2)
READS SQL DATA
begin
    declare lat1, lon1, lat2, lon2 DECIMAL(10,6);
    declare distancia DECIMAL(10,2);
    
    -- Obtenção de da primeira localização
    SELECT latitude, longitude INTO lat1, lon1
    FROM Localizacao WHERE idLocalizacao = loc1_id;
    
    -- Obtenção de coordenadas da segunda localização
    SELECT latitude, longitude INTO lat2, lon2
    FROM Localizacao WHERE idLocalizacao = loc2_id;
    
    -- Fórmula simplificada de distância 
    SET distancia = SQRT(POW(69.1 * (lat2 - lat1), 2) + 
                        POW(69.1 * (lon2 - lon1) * COS(lat1 / 57.3), 2));
    
    return ROUND(distancia, 2);
end $$
delimiter ;
-- teste
SELECT 
    l1.nome AS local_1,
    l2.nome AS local_2,
    calcular_distancia_simulada(l1.idLocalizacao, l2.idLocalizacao) AS distancia_km
FROM Localizacao l1, Localizacao l2
WHERE l1.idLocalizacao <> l2.idLocalizacao
LIMIT 10;

-- 7  Prever Reabastecimento por Semente
delimiter $$
create function previsao_reabastecimento(semente_id INT, dias_projecao INT)
returns VARCHAR(50)
READS SQL DATA
begin
    declare estoque_atual INT;
    declare consumo_medio_diario DECIMAL(10,2);
    declare dias_restantes INT;
    declare previsao VARCHAR(50);
    
    -- Obter estoque atual da semente
    SELECT COALESCE(SUM(e.quantDisponivel), 0) INTO estoque_atual
    FROM Estoque e
    INNER JOIN Lote l ON e.idEstoque = l.Estoque_idEstoque
    WHERE l.Sementes_idSementes = semente_id;
    
    -- Calcular consumo médio diário (últimos 30 dias)
    SELECT COALESCE(SUM(d.quantDistrib) / 30, 0) INTO consumo_medio_diario
    FROM Distribuidor d
    INNER JOIN Sementes s ON d.idDistribuidor = s.Distribuidor_idDistribuidor
    WHERE s.idSementes = semente_id
    AND d.dataDistrib >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    
    -- Calcular dias restantes de estoque
    IF consumo_medio_diario > 0 THEN
        SET dias_restantes = estoque_atual / consumo_medio_diario;
    ELSE
        SET dias_restantes = 999; -- Estoque infinito se não há consumo
    END IF;
    
    -- Determinar previsão
    IF dias_restantes <= dias_projecao THEN
        SET previsao = 'REABASTECER URGENTE';
    ELSEIF dias_restantes <= (dias_projecao * 2) THEN
        SET previsao = 'REABASTECER EM BREVE';
    ELSE
        SET previsao = 'ESTOQUE SUFICIENTE';
    END IF;
    
    return previsao;
end $$
delimiter ;
-- teste 
SELECT 
    s.idSementes,
    s.nomeComum,
    previsao_reabastecimento(s.idSementes, 30) AS previsao_30_dias,
    previsao_reabastecimento(s.idSementes, 60) AS previsao_60_dias
FROM Sementes s;

-- Procedures (favor rodar uma por uma UWU)
-- 1° procedure para para atualizar quantidade em estoque. Uma procedure que atualiza a quantidade disponível no estoque quando um novo lote é recebido.
DELIMITER //
CREATE PROCEDURE RegistrarNovoLoteEAtualizarEstoque(
    IN p_idLote INT,
    IN p_precUnit DECIMAL(10,2),
    IN p_dataAquisic DATETIME,
    IN p_dataValid DATE,
    IN p_quantReceb INT,
    IN p_idEstoque INT,
    IN p_idSementes INT,
    IN p_idDistribuidor INT,
    IN p_idFornecedor INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Erro ao processar o lote. Transação cancelada.' AS Mensagem;
    END;
    
    START TRANSACTION;
    
    -- Atualiza o estoque
    UPDATE Estoque 
    SET quantDisponivel = quantDisponivel + p_quantReceb 
    WHERE idEstoque = p_idEstoque;
    
    -- Insere o novo lote com todos os dados
    INSERT INTO Lote (
        idLote, 
        precUnit, 
        dataAquisic, 
        dataValid, 
        quantReceb, 
        Estoque_idEstoque, 
        Sementes_idSementes, 
        Sementes_Distribuidor_idDistribuidor, 
        Fornecedor_idFornecedor
    ) VALUES (
        p_idLote,
        p_precUnit,
        p_dataAquisic,
        p_dataValid,
        p_quantReceb,
        p_idEstoque,
        p_idSementes,
        p_idDistribuidor,
        p_idFornecedor
    );
    COMMIT;
    SELECT 'Lote registrado e estoque atualizado com sucesso.' AS Mensagem;
END //
DELIMITER ;

CALL RegistrarNovoLoteEAtualizarEstoque(
    1001,                     
    15.50,                    
    '2024-12-03 10:00:00',   
    '2025-12-03',          
    500,                    
    1,                        
    1,                        
    1,                        
    1                         
);

-- 2° Procedure para verificar validade de lotes: Crie uma procedure que liste todos os lotes com data de validade próxima
DELIMITER //
CREATE PROCEDURE VerificarLotesProximoVencimento()
BEGIN
    -- Lista lotes que vencerão nos próximos 30 dias
    SELECT 
        l.idLote AS 'Número do Lote',
        s.nomeComum AS 'Nome da Semente',
        s.nomeCientifico AS 'Nome Científico',
        f.nome AS 'Fornecedor',
        l.dataAquisic AS 'Data de Aquisição',
        l.dataValid AS 'Data de Validade',
        DATEDIFF(l.dataValid, CURDATE()) AS 'Dias Restantes',
        l.quantReceb AS 'Quantidade Recebida',
        e.quantDisponivel AS 'Quantidade em Estoque',
        a.nome AS 'Armazém',
        loc.nome AS 'Localização'
    FROM 
        Lote l
    JOIN 
        Sementes s ON l.Sementes_idSementes = s.idSementes AND l.Sementes_Distribuidor_idDistribuidor = s.Distribuidor_idDistribuidor
    JOIN 
        Fornecedor f ON l.Fornecedor_idFornecedor = f.idFornecedor
    JOIN 
        Estoque e ON l.Estoque_idEstoque = e.idEstoque
    JOIN 
        Estoque_has_Armazem ea ON e.idEstoque = ea.Estoque_idEstoque
    JOIN 
        Armazem a ON ea.Armazem_idArmazem = a.idArmazem AND ea.Armazem_Distribuidor_idDistribuidor = a.Distribuidor_idDistribuidor
    JOIN 
        Localizacao loc ON a.Localizacao_idLocalizacao = loc.idLocalizacao
    WHERE 
        l.dataValid BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
    ORDER BY 
        l.dataValid ASC;
END //
DELIMITER ;

CALL VerificarLotesProximoVencimento();

-- 3°
DELIMITER //
CREATE PROCEDURE CadastrarNovoCliente(
    IN p_nome VARCHAR(45),
    IN p_cpf VARCHAR(14),
    IN p_cnpj VARCHAR(18),
    IN p_tipo VARCHAR(45),
    IN p_telefone_numero VARCHAR(15),
    IN p_rua VARCHAR(40),
    IN p_bairro VARCHAR(40),
    IN p_numero INT,
    IN p_cidade VARCHAR(45),
    IN p_cep VARCHAR(9),
    IN p_uf CHAR(2),
    OUT p_mensagem VARCHAR(100)
)
BEGIN
    DECLARE v_idCliente INT;
    DECLARE v_idTelefone INT;
    DECLARE v_idEndereco INT;
    DECLARE v_telefone_existe INT;
    DECLARE v_endereco_existe INT;
    
    -- Verificar se o CPF/CNPJ já existe
    IF (p_cpf IS NOT NULL AND EXISTS (SELECT 1 FROM Cliente WHERE CPF = p_cpf)) OR
       (p_cnpj IS NOT NULL AND EXISTS (SELECT 1 FROM Cliente WHERE CNPJ = p_cnpj)) THEN
        SET p_mensagem = 'Erro: Cliente já cadastrado com este CPF/CNPJ';
    ELSE
        -- Verificar se o telefone já existe
        SELECT idTelefone INTO v_idTelefone FROM Telefone WHERE numero = p_telefone_numero LIMIT 1;
        
        IF v_idTelefone IS NULL THEN
            -- Telefone não existe, criar novo
            SELECT IFNULL(MAX(idTelefone), 0) + 1 INTO v_idTelefone FROM Telefone;
            INSERT INTO Telefone (idTelefone, numero) VALUES (v_idTelefone, p_telefone_numero);
        END IF;
        
        -- Verificar se o endereço já existe
        SELECT idEndereco INTO v_idEndereco FROM Endereco 
        WHERE rua = p_rua AND bairro = p_bairro AND numero = p_numero 
        AND cidade = p_cidade AND CEP = p_cep AND UF = p_uf LIMIT 1;
        
        IF v_idEndereco IS NULL THEN
            -- Endereço não existe, criar novo
            SELECT IFNULL(MAX(idEndereco), 0) + 1 INTO v_idEndereco FROM Endereco;
            INSERT INTO Endereco (idEndereco, rua, bairro, numero, cidade, CEP, UF)
            VALUES (v_idEndereco, p_rua, p_bairro, p_numero, p_cidade, p_cep, p_uf);
        END IF;
        
        -- Criar o cliente
        SELECT IFNULL(MAX(idCliente), 0) + 1 INTO v_idCliente FROM Cliente;
        
        INSERT INTO Cliente (idCliente, CPF, CNPJ, tipo, Telefone_idTelefone, Endereco_idEndereco, nome)
        VALUES (v_idCliente, p_cpf, p_cnpj, p_tipo, v_idTelefone, v_idEndereco, p_nome);
        
        SET p_mensagem = CONCAT('Cliente cadastrado com sucesso! ID: ', v_idCliente);
    END IF;
END //
DELIMITER ;



CALL CadastrarNovoCliente(
    'João da Silva',        
    '123.456.789-01',        
    NULL,                     
    'Pessoa Física',          
    '(11) 99999-8888',       
    'Rua das Flores',         
    'Centro',                
    100,                      
    'São Paulo',             
    '01234-567',              
    'SP',                     
    @mensagem                
);

SELECT @mensagem AS Resultado;

-- Para cliente pessoa jurídica (com CNPJ)

CALL CadastrarNovoCliente(
    'Fazenda Modelo Ltda',   
    NULL,                     
    '12.345.678/0001-90',    
    'Pessoa Jurídica',        
    '(11) 3333-4444',        
    'Avenida Brasil',         
    'Jardins',               
    500,                     
    'São Paulo',              
    '04567-890',              
    'SP',                     
    @mensagem                
);

SELECT @mensagem AS Resultado;

-- 4° procedure de cadastro de fornecedor
DELIMITER $$
CREATE PROCEDURE cadastrarFornecedor(
    IN p_idFornecedor INT,
    IN p_nome VARCHAR(45),
    IN p_cnpj VARCHAR(18),
    IN p_cpf VARCHAR(14),
    IN p_telefone1 VARCHAR(15),
    IN p_telefone2 VARCHAR(15),
    IN p_rua VARCHAR(40),
    IN p_bairro VARCHAR(40),
    IN p_numero INT,
    IN p_cidade VARCHAR(45),
    IN p_cep VARCHAR(9),
    IN p_uf CHAR(2)
)
BEGIN
    DECLARE v_idTelefone INT DEFAULT 0;
    DECLARE v_idEndereco INT DEFAULT 0;
    
    INSERT INTO Fornecedor (idFornecedor, nome, CNPJ, CPF)
    VALUES (p_idFornecedor, p_nome, p_cnpj, p_cpf);
    
    INSERT INTO Telefone (numero) VALUES (p_telefone1);
    SET v_idTelefone = LAST_INSERT_ID();
    
    IF(p_telefone2 IS NOT NULL) THEN
        INSERT INTO Telefone (numero) VALUES (p_telefone2);
    END IF;
    
    INSERT INTO Endereco (rua, bairro, numero, cidade, CEP, UF)
    VALUES (p_rua, p_bairro, p_numero, p_cidade, p_cep, p_uf);
    
    SET v_idEndereco = LAST_INSERT_ID();
    
    INSERT INTO Fornecedor_has_Distribuidor (Fornecedor_idFornecedor, Distribuidor_idDistribuidor)
    VALUES (p_idFornecedor, 1);
    
    SELECT CONCAT('Fornecedor ', p_nome, ' cadastrado com sucesso!') AS Mensagem;
END $$
DELIMITER ; 

CALL cadastrarFornecedor(45, 'Sementes São Paulo', '12.345.678/0001-90', NULL, 
                         '(11) 99999-8888', '(11) 3333-4444', 
                         'Rua das Flores', 'Centro', 123, 'São Paulo', 
                         '01234-567', 'SP');

-- 5° procedure de registro de novo tipo de semente
DELIMITER $$
CREATE PROCEDURE registrarSemente(
    IN p_idSementes INT,
    IN p_origem VARCHAR(45),
    IN p_nomeComum VARCHAR(45),
    IN p_nomeCientifico VARCHAR(45),
    IN p_idDistribuidor INT,
    IN p_idEstoque INT,
    IN p_quantidadeInicial INT
)
BEGIN
    DECLARE v_estoque_existe INT DEFAULT 0;

    SELECT COUNT(*) INTO v_estoque_existe
    FROM Estoque
    WHERE idEstoque = p_idEstoque;
    
    IF(v_estoque_existe = 0) THEN
        INSERT INTO Estoque (idEstoque, quantDisponivel, quantSaida)
        VALUES (p_idEstoque, p_quantidadeInicial, 0);
    END IF;

    INSERT INTO Sementes (idSementes, origem, nomeComum, nomeCientifico, Distribuidor_idDistribuidor)
    VALUES (p_idSementes, p_origem, p_nomeComum, p_nomeCientifico, p_idDistribuidor);
    
    SELECT CONCAT('Semente ', p_nomeComum, ' registrada com sucesso!') AS Mensagem;
END $$
DELIMITER ;

CALL registrarSemente(72, 'Importada', 'Milho', 'Zea mays', 1, 1, 1000);

-- 6° procedure para realizar pedido
DELIMITER $$
CREATE PROCEDURE realizarPedido(
    IN p_idCliente INT,
    IN p_idSementes INT,
    IN p_quantidade INT,
    IN p_idLote INT
)
BEGIN
    DECLARE v_idPedido INT DEFAULT 0;
    DECLARE v_preco_unitario DECIMAL(10,2) DEFAULT 0.0;
    DECLARE v_estoque_disponivel INT DEFAULT 0;

    SELECT e.quantDisponivel, l.precUnit 
    INTO v_estoque_disponivel, v_preco_unitario
    FROM Estoque e
    JOIN Lote l ON e.idEstoque = l.Estoque_idEstoque
    WHERE l.idLote = p_idLote;
    
    IF(v_estoque_disponivel >= p_quantidade) THEN
        INSERT INTO Pedido (dataPedido, status)
        VALUES (NOW(), 'PENDENTE');
        
        SET v_idPedido = LAST_INSERT_ID();

        INSERT INTO Cliente_has_Pedido (Cliente_idCliente, Pedido_idPedido)
        VALUES (p_idCliente, v_idPedido);

        INSERT INTO itemPedido (quantPedida, precoUnitario, Pedido_idPedido, Lote_idLote)
        VALUES (p_quantidade, v_preco_unitario, v_idPedido, p_idLote);

        UPDATE Pedido 
        SET status = 'PROCESSANDO'
        WHERE idPedido = v_idPedido;
        
        SELECT CONCAT('Pedido #', v_idPedido, ' realizado com sucesso!') AS Mensagem;
    ELSE
        SELECT CONCAT('Estoque insuficiente. Disponível: ', v_estoque_disponivel) AS Erro;
    END IF;
END $$
DELIMITER ;

CALL realizarPedido(1, 1, 50, 1);
 
 -- 7° procedure para registrar entrega de distribuição 
 DELIMITER $$
CREATE PROCEDURE registrarEntregaDistribuicao(
    IN p_idDistribuidor INT,
    IN p_quantidade DECIMAL(10,2),
    IN p_localEntrega VARCHAR(45),
    IN p_idSementes INT,
    IN p_idCliente INT
)
BEGIN
    DECLARE v_estoque_atual INT DEFAULT 0;
    DECLARE v_idEstoque INT DEFAULT 0;

    SELECT e.idEstoque, e.quantDisponivel
    INTO v_idEstoque, v_estoque_atual
    FROM Estoque e
    JOIN Lote l ON e.idEstoque = l.Estoque_idEstoque
    WHERE l.Sementes_idSementes = p_idSementes
    LIMIT 1;
    
    IF(v_estoque_atual >= p_quantidade) THEN
        INSERT INTO Distribuidor (idDistribuidor, dataDistrib, quantDistrib, localEntrega)
        VALUES (p_idDistribuidor, NOW(), p_quantidade, p_localEntrega);

        UPDATE Estoque
        SET quantDisponivel = quantDisponivel - p_quantidade,
            quantSaida = quantSaida + p_quantidade
        WHERE idEstoque = v_idEstoque;

        INSERT INTO Pedido (dataPedido, status)
        VALUES (NOW(), 'ENTREGUE');
        
        SELECT CONCAT('Distribuição registrada para cliente ID ', p_idCliente, 
                     '. Quantidade: ', p_quantidade) AS Mensagem;
    ELSE
        SELECT CONCAT('Estoque insuficiente para distribuição. Disponível: ', 
                     v_estoque_atual) AS Erro;
    END IF;
END $$
DELIMITER ;

CALL registrarEntregaDistribuicao(76, 50.0, 'Fazenda Boa Vista', 1, 1);
