-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema distribuicao_de_sementes
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `distribuicao_de_sementes` DEFAULT CHARACTER SET utf8 ;
USE `distribuicao_de_sementes` ;

-- -----------------------------------------------------
-- Table `Fornecedor`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Fornecedor` (
  `idFornecedor` INT NOT NULL,
  `nome` VARCHAR(45) NULL,
  `CNPJ` VARCHAR(18) NULL,
  `CPF` VARCHAR(14) NULL,
  PRIMARY KEY (`idFornecedor`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Telefone`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Telefone` (
  `idTelefone` INT NOT NULL AUTO_INCREMENT,
  `numero` VARCHAR(15) NULL,
  PRIMARY KEY (`idTelefone`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Distribuidor`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Distribuidor` (
  `idDistribuidor` INT NOT NULL,
  `dataDistrib` DATETIME NULL,
  `quantDistrib` DECIMAL(10,2) NULL,
  `localEntrega` VARCHAR(45) NULL,
  PRIMARY KEY (`idDistribuidor`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Sementes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Sementes` (
  `idSementes` INT NOT NULL,
  `origem` VARCHAR(45) NULL,
  `nomeComum` VARCHAR(45) NULL,
  `nomeCientifico` VARCHAR(45) NULL,
  `Distribuidor_idDistribuidor` INT NOT NULL,
  PRIMARY KEY (`idSementes`, `Distribuidor_idDistribuidor`),
  INDEX `fk_Sementes_Distribuidor1_idx` (`Distribuidor_idDistribuidor` ASC),
  CONSTRAINT `fk_Sementes_Distribuidor1`
    FOREIGN KEY (`Distribuidor_idDistribuidor`)
    REFERENCES `Distribuidor` (`idDistribuidor`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Estoque`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Estoque` (
  `idEstoque` INT NOT NULL,
  `quantDisponivel` INT NULL,
  `quantSaida` INT NULL,
  PRIMARY KEY (`idEstoque`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Lote`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Lote` (
  `idLote` INT NOT NULL,
  `precUnit` INT NULL,
  `dataAquisic` DATETIME NULL,
  `dataValid` DATE NULL,
  `quantReceb` INT NULL,
  `Estoque_idEstoque` INT NOT NULL,
  `Sementes_idSementes` INT NOT NULL,
  `Sementes_Distribuidor_idDistribuidor` INT NOT NULL,
  `Fornecedor_idFornecedor` INT NOT NULL,
  PRIMARY KEY (`idLote`),
  INDEX `fk_Lote_Estoque1_idx` (`Estoque_idEstoque` ASC),
  INDEX `fk_Lote_Sementes1_idx` (`Sementes_idSementes` ASC, `Sementes_Distribuidor_idDistribuidor` ASC),
  INDEX `fk_Lote_Fornecedor1_idx` (`Fornecedor_idFornecedor` ASC),
  CONSTRAINT `fk_Lote_Estoque1`
    FOREIGN KEY (`Estoque_idEstoque`)
    REFERENCES `Estoque` (`idEstoque`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Lote_Sementes1`
    FOREIGN KEY (`Sementes_idSementes`, `Sementes_Distribuidor_idDistribuidor`)
    REFERENCES `Sementes` (`idSementes`, `Distribuidor_idDistribuidor`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Lote_Fornecedor1`
    FOREIGN KEY (`Fornecedor_idFornecedor`)
    REFERENCES `Fornecedor` (`idFornecedor`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Localizacao`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Localizacao` (
  `idLocalizacao` INT NOT NULL,
  `nome` VARCHAR(45) NULL,
  `latitude` DECIMAL(10,6) NULL,
  `longitude` DECIMAL(10,6) NULL,
  PRIMARY KEY (`idLocalizacao`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Armazem`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Armazem` (
  `idArmazem` INT NOT NULL,
  `nome` VARCHAR(45) NULL,
  `capacMax` INT NULL,
  `responsavel` VARCHAR(45) NULL,
  `Distribuidor_idDistribuidor` INT NOT NULL,
  `Localizacao_idLocalizacao` INT NOT NULL,
  PRIMARY KEY (`idArmazem`, `Distribuidor_idDistribuidor`),
  INDEX `fk_Armazem_Distribuidor1_idx` (`Distribuidor_idDistribuidor` ASC),
  INDEX `fk_Armazem_Localizacao1_idx` (`Localizacao_idLocalizacao` ASC),
  CONSTRAINT `fk_Armazem_Distribuidor1`
    FOREIGN KEY (`Distribuidor_idDistribuidor`)
    REFERENCES `Distribuidor` (`idDistribuidor`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Armazem_Localizacao1`
    FOREIGN KEY (`Localizacao_idLocalizacao`)
    REFERENCES `Localizacao` (`idLocalizacao`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Endereco`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Endereco` (
  `idEndereco` INT NOT NULL AUTO_INCREMENT,
  `rua` VARCHAR(40) NULL,
  `bairro` VARCHAR(40) NULL,
  `numero` INT NULL,
  `cidade` VARCHAR(45) NULL,
  `CEP` VARCHAR(9) NULL,
  `UF` CHAR(2) NULL,
  PRIMARY KEY (`idEndereco`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Cliente`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Cliente` (
  `idCliente` INT NOT NULL,
  `CPF` VARCHAR(14) NULL,
  `CNPJ` VARCHAR(18) NULL,
  `tipo` VARCHAR(45) NULL,
  `Telefone_idTelefone` INT NOT NULL,
  `Endereco_idEndereco` INT NOT NULL,
  `nome` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`idCliente`),
  INDEX `fk_Cliente_Telefone_idx` (`Telefone_idTelefone` ASC),
  INDEX `fk_Cliente_Endereco1_idx` (`Endereco_idEndereco` ASC),
  CONSTRAINT `fk_Cliente_Telefone`
    FOREIGN KEY (`Telefone_idTelefone`)
    REFERENCES `Telefone` (`idTelefone`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Cliente_Endereco1`
    FOREIGN KEY (`Endereco_idEndereco`)
    REFERENCES `Endereco` (`idEndereco`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Fornecedor_has_Distribuidor`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Fornecedor_has_Distribuidor` (
  `Fornecedor_idFornecedor` INT NOT NULL,
  `Distribuidor_idDistribuidor` INT NOT NULL,
  PRIMARY KEY (`Fornecedor_idFornecedor`, `Distribuidor_idDistribuidor`),
  INDEX `fk_Fornecedor_has_Distribuidor_Distribuidor1_idx` (`Distribuidor_idDistribuidor` ASC),
  INDEX `fk_Fornecedor_has_Distribuidor_Fornecedor1_idx` (`Fornecedor_idFornecedor` ASC),
  CONSTRAINT `fk_Fornecedor_has_Distribuidor_Fornecedor1`
    FOREIGN KEY (`Fornecedor_idFornecedor`)
    REFERENCES `Fornecedor` (`idFornecedor`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Fornecedor_has_Distribuidor_Distribuidor1`
    FOREIGN KEY (`Distribuidor_idDistribuidor`)
    REFERENCES `Distribuidor` (`idDistribuidor`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Estoque_has_Armazem` (AJUSTADA)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Estoque_has_Armazem` (
  `Estoque_idEstoque` INT NOT NULL,
  `Armazem_idArmazem` INT NOT NULL,
  `Armazem_Distribuidor_idDistribuidor` INT NOT NULL,
  PRIMARY KEY (`Estoque_idEstoque`, `Armazem_idArmazem`, `Armazem_Distribuidor_idDistribuidor`),
  INDEX `fk_Estoque_has_Armazem_Armazem1_idx` (`Armazem_idArmazem`, `Armazem_Distribuidor_idDistribuidor` ASC),
  INDEX `fk_Estoque_has_Armazem_Estoque1_idx` (`Estoque_idEstoque` ASC),
  CONSTRAINT `fk_Estoque_has_Armazem_Estoque1`
    FOREIGN KEY (`Estoque_idEstoque`)
    REFERENCES `Estoque` (`idEstoque`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Estoque_has_Armazem_Armazem1`
    FOREIGN KEY (`Armazem_idArmazem`, `Armazem_Distribuidor_idDistribuidor`)
    REFERENCES `Armazem` (`idArmazem`, `Distribuidor_idDistribuidor`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Pedido`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Pedido` (
  `idPedido` INT NOT NULL AUTO_INCREMENT,
  `dataPedido` DATETIME NULL,
  `status` VARCHAR(45) NULL,
  PRIMARY KEY (`idPedido`)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Cliente_has_Pedido`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Cliente_has_Pedido` (
  `Cliente_idCliente` INT NOT NULL,
  `Pedido_idPedido` INT NOT NULL,
  PRIMARY KEY (`Cliente_idCliente`, `Pedido_idPedido`),
  INDEX `fk_Cliente_has_Pedido_Pedido1_idx` (`Pedido_idPedido` ASC),
  INDEX `fk_Cliente_has_Pedido_Cliente1_idx` (`Cliente_idCliente` ASC),
  CONSTRAINT `fk_Cliente_has_Pedido_Cliente1`
    FOREIGN KEY (`Cliente_idCliente`)
    REFERENCES `Cliente` (`idCliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Cliente_has_Pedido_Pedido1`
    FOREIGN KEY (`Pedido_idPedido`)
    REFERENCES `Pedido` (`idPedido`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `itemPedido`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `itemPedido` (
  `iditemPedido` INT NOT NULL AUTO_INCREMENT,
  `quantPedida` INT NULL,
  `precoUnitario` VARCHAR(45) NULL,
  `Pedido_idPedido` INT NOT NULL,
  `Lote_idLote` INT NOT NULL,
  PRIMARY KEY (`iditemPedido`, `Pedido_idPedido`),
  INDEX `fk_itemPedido_Pedido1_idx` (`Pedido_idPedido` ASC),
  INDEX `fk_itemPedido_Lote1_idx` (`Lote_idLote` ASC),
  CONSTRAINT `fk_itemPedido_Pedido1`
    FOREIGN KEY (`Pedido_idPedido`)
    REFERENCES `Pedido` (`idPedido`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_itemPedido_Lote1`
    FOREIGN KEY (`Lote_idLote`)
    REFERENCES `Lote` (`idLote`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
