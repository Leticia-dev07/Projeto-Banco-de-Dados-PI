-- triggers

-- 1° validar a data de validade
DELIMITER $$
CREATE TRIGGER valida_data_validade_lote
BEFORE INSERT ON Lote
FOR EACH ROW
BEGIN
    IF NEW.dataValid < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Data de validade não pode ser anterior à data atual';
    END IF;
 
    IF NEW.dataValid < NEW.dataAquisic THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Data de validade não pode ser anterior à data de aquisição';
    END IF;

    IF NEW.dataAquisic > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Data de aquisição não pode ser futura';
    END IF;
END $$
DELIMITER ;

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
    1,
    100,
    '2024-03-20 10:00:00',
    '2023-12-31',  -- Data no passado
    500,
    1,
    1,
    1,
    1
);

-- 2° atualização automática de estoque
DELIMITER $$

CREATE TRIGGER atualiza_estoque_apos_pedido
AFTER INSERT ON itemPedido
FOR EACH ROW
BEGIN
    DECLARE v_estoque_id INT;
    DECLARE v_quant_disponivel INT;

    SELECT l.Estoque_idEstoque, e.quantDisponivel 
    INTO v_estoque_id, v_quant_disponivel
    FROM Lote l
    INNER JOIN Estoque e ON l.Estoque_idEstoque = e.idEstoque
    WHERE l.idLote = NEW.Lote_idLote;

    IF v_estoque_id IS NOT NULL THEN
        IF v_quant_disponivel >= NEW.quantPedida THEN
            UPDATE Estoque 
            SET quantDisponivel = quantDisponivel - NEW.quantPedida,
                quantSaida = quantSaida + NEW.quantPedida
            WHERE idEstoque = v_estoque_id;
        ELSE
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'ATENÇÃO: Estoque insuficiente!';
        END IF;
    END IF;
END$$

DELIMITER ;

SELECT * FROM Estoque WHERE idEstoque = 1;

INSERT INTO itemPedido (quantPedida, precoUnitario, Pedido_idPedido, Lote_idLote)
VALUES (1000, '25.50', 1, 1);

SELECT * FROM Estoque WHERE idEstoque = 1;

-- 3° Validar Preço Unitário Mínimo do Lote    
DELIMITER $$
CREATE TRIGGER valida_preco_minimo_lote
BEFORE INSERT ON Lote
FOR EACH ROW
BEGIN
    IF NEW.precUnit < 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Preço unitário não pode ser inferior a R$ 1,00';
    END IF;
END $$
DELIMITER ;
SHOW TRIGGERS LIKE 'Lote';

-- teste
INSERT INTO Lote VALUES
(107, 0, '2024-07-01 10:00:00', '2026-07-01', 80, 1, 1, 1, 1);

-- 4 Validar quantidade recebida do lote 
DELIMITER $$
CREATE TRIGGER valida_quantidade_recebida_lote
BEFORE INSERT ON Lote
FOR EACH ROW
BEGIN
    IF NEW.quantReceb <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Quantidade recebida não pode ser zero ou negativa';
    END IF;
END $$
DELIMITER ;

-- 5 Atualizar estoque ao adicionar lote
DELIMITER $$
CREATE TRIGGER atualiza_estoque_apos_lote
AFTER INSERT ON Lote
FOR EACH ROW
BEGIN
    UPDATE Estoque
    SET quantDisponivel = quantDisponivel + NEW.quantReceb
    WHERE idEstoque = NEW.Estoque_idEstoque;
END $$
DELIMITER ;
INSERT INTO Lote VALUES
(300, 10, '2024-11-01 10:00:00', '2026-11-01', 50, 10, 1, 1, 1);
SELECT * FROM Estoque WHERE idEstoque = 10;

-- 6 Impedir estoque negativo ao atualizar itemPedido
DELIMITER $$
CREATE TRIGGER evita_estoque_negativo_item
BEFORE UPDATE ON Estoque
FOR EACH ROW
BEGIN
    IF NEW.quantDisponivel < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Estoque não pode ficar negativo!';
    END IF;
END $$
DELIMITER ;
UPDATE Estoque
SET quantDisponivel = -10
WHERE idEstoque = 10;

-- 7 Validar data do Pedido
DELIMITER $$
CREATE TRIGGER valida_data_pedido
BEFORE INSERT ON Pedido
FOR EACH ROW
BEGIN
    IF NEW.dataPedido > NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Data do pedido não pode ser futura';
    END IF;
END $$
DELIMITER ;
INSERT INTO Pedido (idPedido, dataPedido)
VALUES (500, '2030-01-01 00:00:00');

-- 8 Garantir que cliente só tenha um CPF ou CNPJ preenchido
DELIMITER $$
CREATE TRIGGER valida_documento_cliente
BEFORE INSERT ON Cliente
FOR EACH ROW
BEGIN
    IF NEW.CPF IS NULL AND NEW.CNPJ IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Cliente deve ter CPF ou CNPJ';
    END IF;
END $$
DELIMITER ;
INSERT INTO Cliente (idCliente, nome)
VALUES (600, 'Cliente Sem Documento');

-- 9 Impedir Preço Unitário inválido em itemPedido
DELIMITER $$
CREATE TRIGGER valida_preco_item
BEFORE INSERT ON itemPedido
FOR EACH ROW
BEGIN
    IF NEW.precoUnitario <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Preço unitário do item deve ser positivo';
    END IF;
END $$
DELIMITER ;
DESCRIBE itemPedido;
INSERT INTO itemPedido (quantPedida, precoUnitario, Pedido_idPedido, Lote_idLote)
VALUES (5, -10, 501, 301);

-- 10 Impedir que um Armazém exceda a capacidade máxima 
DELIMITER $$
CREATE TRIGGER valida_capacidade_armazem
BEFORE INSERT ON Estoque_has_Armazem
FOR EACH ROW
BEGIN
    DECLARE capacidade INT;
    DECLARE totalEstoque INT;
    DECLARE quantidade_novo_estoque INT;
    DECLARE total_final INT;
    
    -- Busca a capacidade do armazém
    SELECT capacMax INTO capacidade
    FROM Armazem
    WHERE idArmazem = NEW.Armazem_idArmazem 
      AND Distribuidor_idDistribuidor = NEW.Armazem_Distribuidor_idDistribuidor;
    
    -- Se não encontrar o armazém
    IF capacidade IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Armazem nao encontrado!';
    END IF;
    
    -- Busca a quantidade do novo estoque
    SELECT quantDisponivel INTO quantidade_novo_estoque
    FROM Estoque
    WHERE idEstoque = NEW.Estoque_idEstoque;
    
    -- Se não encontrar o estoque
    IF quantidade_novo_estoque IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Estoque nao encontrado!';
    END IF;
    
    -- Calcula o total atual de estoque no armazém
    SELECT COALESCE(SUM(e.quantDisponivel), 0) INTO totalEstoque
    FROM Estoque e
    INNER JOIN Estoque_has_Armazem ea ON e.idEstoque = ea.Estoque_idEstoque
    WHERE ea.Armazem_idArmazem = NEW.Armazem_idArmazem
      AND ea.Estoque_idEstoque != NEW.Estoque_idEstoque;
    
    -- Calcula o total final
    SET total_final = totalEstoque + quantidade_novo_estoque;
    
    -- Verifica se o novo estoque excede a capacidade
    IF total_final > capacidade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Capacidade maxima do armazem seria excedida!';
    END IF;
END $$
DELIMITER ;
-- Primeiro insert deve funcionar
INSERT INTO Estoque_has_Armazem 
(Estoque_idEstoque, Armazem_idArmazem, Armazem_Distribuidor_idDistribuidor)
VALUES 
(1, 20, 20);
INSERT INTO Estoque_has_Armazem 
(Estoque_idEstoque, Armazem_idArmazem, Armazem_Distribuidor_idDistribuidor)
VALUES 
(6, 20, 20);
-- Segundo insert deve falhar (40 + 70 = 110 > 100)
INSERT INTO Estoque_has_Armazem 
(Estoque_idEstoque, Armazem_idArmazem, Armazem_Distribuidor_idDistribuidor)
VALUES 
(2, 20, 20);

-- 11 Validar latitude/longitude 
DELIMITER $$
CREATE TRIGGER valida_localizacao
BEFORE INSERT ON Localizacao
FOR EACH ROW
BEGIN
    IF NEW.latitude < -90 OR NEW.latitude > 90 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Latitude inválida!';
    END IF;

    IF NEW.longitude < -180 OR NEW.longitude > 180 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Longitude inválida!';
    END IF;
END $$
DELIMITER ;
-- Teste 4: Longitude inválida (< -180) - deve falhar
INSERT INTO Localizacao (idLocalizacao, nome, latitude, longitude)
VALUES (903, 'Teste Longitude Inválida Negativa', 50, -190);

-- Teste 5: Dados válidos - deve funcionar
INSERT INTO Localizacao (idLocalizacao, nome, latitude, longitude)
VALUES (904, 'Localização Válida', -23.550520, -46.633308);



-- 12 Impedir inserir telefone vazio 
DELIMITER $$
CREATE TRIGGER valida_telefone
BEFORE INSERT ON Telefone
FOR EACH ROW
BEGIN
    IF NEW.numero IS NULL OR NEW.numero = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Telefone não pode ser vazio';
    END IF;
END $$
DELIMITER ;
-- Teste 1: Telefone vazio (string vazia) - deve falhar
INSERT INTO Telefone VALUES (1000, '');
-- Teste 3: Telefone válido - deve funcionar
INSERT INTO Telefone VALUES (1002, '(11) 98765-4321');


