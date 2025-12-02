# 📦 Vida em Grão — Sistema de Gestão de Estoque de Sementes

Sistema de Banco de Dados desenvolvido para controlar **estoque, armazéns, fornecedores, clientes, pedidos e lotes de sementes**.  
Inclui **validações automáticas com triggers**, garantindo consistência e segurança dos dados.

---

## 📌 Objetivo do Projeto

Gerenciar todo o ciclo de sementes dentro da cadeia de distribuição:

✔ Cadastrar fornecedores e distribuidores  
✔ Registrar lotes e atualizar estoque automaticamente  
✔ Controlar capacidade dos armazéns  
✔ Registrar clientes e pedidos  
✔ Validar preços, datas e documentos  
✔ Garantir integridade dos dados com regras de negócio

---
## 📚 Importância da Modelagem do Banco de Dados

A modelagem foi realizada em **três etapas fundamentais**:

### 🔹 Modelo Conceitual
Representa a **visão do negócio**, mostrando as entidades e como elas se relacionam no mundo real.  
Ajuda a equipe a entender o sistema antes de qualquer programação.

### 🔹 Modelo Lógico
Transforma o conceito em **estrutura relacional**, definindo:
- Atributos de cada entidade
- Chaves primárias e estrangeiras
- Cardinalidades
- Normalização

### 🔹 Modelo Físico
Implementação no **MySQL**, com:
- Tipos de dados
- Índices
- Restrições
- Regras de integridade

📌 Essa sequência garante que o banco **atenda aos requisitos do cliente sem desperdício de recursos**.

---

## 🧩 Normalização e Organização dos Dados

Durante o desenvolvimento, o banco foi **certificado nas 3 Formas Normais (1FN, 2FN e 3FN)**:

| Forma Normal | Benefício |
|--------------|-----------|
| 1FN | Não há grupos repetidos; dados bem estruturados |
| 2FN | Evita dependências parciais em chaves compostas |
| 3FN | Remove dependências transitivas e redundâncias |

▶ Resultado: um banco **organizado**, **consistente** e **livre de duplicações desnecessárias**.

---

## 🔐 Segurança e Integridade dos Dados

O sistema incorpora **múltiplas camadas de segurança**, incluindo:

- Triggers que **impedem dados inválidos**
- Integridade referencial com **chaves estrangeiras**
- Regras de negócio aplicadas diretamente no banco
- Validações automáticas
- Prevenção de estoques negativos
- Dados geográficos com limites reais (latitude/longitude)

📌 Dessa forma, o banco garante **tranquilidade ao usuário final**,
protegendo o sistema contra erros operacionais e inconsistências.

---

## 🗂️ Arquitetura e Modelagem

O sistema foi projetado seguindo as etapas de modelagem:

| Tipo do Modelo | 
|----------------|
| Modelo Conceitual (DER) | 
| Modelo Lógico | 
| Modelo Físico | 

---

## 🧱 Estrutura do Banco de Dados

Entidades principais do sistema:

- **Sementes**
- **Distribuidor**
- **Fornecedor**
- **Estoque**
- **Armazém**
- **Lote**
- **Pedido**
- **Cliente**
- **ItemPedido**
- **Endereço**
- **Telefone**
- **Localização**

Tabelas associativas:

- **Estoque_has_Armazem**
- **Sementes_has_Pedido**

---

## ⚙️ Scripts SQL

| Categoria | 
|----------|
| Criação do Banco (DDL) |
| Inserts (DML) |
| Triggers | 
| Procedures | 
| Functions | 

---

## 🔥 Triggers Implementados (Regras de Negócio)

| Nº | Função Garantida |
|----|-----------------|
| 1 | Preço mínimo do produto (Lote) |
| 2 | Impedir data de aquisição futura |
| 3 | Validade não pode ser vencida |
| 4 | Quantidade não pode ser negativa |
| 5 | Atualiza estoque automaticamente ao inserir lote |
| 6 | Evita estoque negativo em atualizações |
| 7 | Data do pedido não pode ser futura |
| 8 | Cliente deve ter CPF ou CNPJ |
| 9 | Preço unitário do item deve ser positivo |
|10 | Armazém não pode exceder a capacidade |
|11 | Latitude e longitude válidas |
|12 | Telefone não pode ser vazio |

## 🧪 Exemplos de Teste dos Triggers

### ❌ Teste: Preço unitário menor que o mínimo

---
## 🧾 Conclusão

O **Vida em Grão** é um projeto robusto e escalável, desenvolvido com foco em:

✨ Segurança  
✨ Confiabilidade  
✨ Boas práticas de modelagem  
✨ Regras do domínio do agronegócio  

Ele demonstra domínio dos conceitos essenciais de Banco de Dados e está preparado para evolução futura!

### 🌐 Contatos

**📚 Danilo Farias (Professor responsável pelo projeto)**  
[![GitHub](https://img.shields.io/badge/GitHub-000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/dansoaresfarias/dansoaresfarias) [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/dansoaresfarias/)

**Leticia Gabrielle**  
[![GitHub](https://img.shields.io/badge/GitHub-000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Leticia-dev07/Leticia-dev07) [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/leticia-gabrielle-034b80327)  

**Caio Victor**  
[![GitHub](https://img.shields.io/badge/GitHub-000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Caio-Paschoal97/Caio-Paschoal97) [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/caio-victor-7b6661359/) 

**Priscila**  
[![GitHub](https://img.shields.io/badge/GitHub-000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Priscila319) [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/victor-pereira-b86aa8256/) 

**André Salgado**  
[![GitHub](https://img.shields.io/badge/GitHub-000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/andrecsf/andrecsf) [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://br.linkedin.com/in/andr%C3%A9-salgado-8652ba269) 

**Luciana Borges**  
[![GitHub](https://img.shields.io/badge/GitHub-000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Luciana25956/Luciana25956) [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/luciana-borges-12a283351/)  

**Arice Lustosa**  
[![GitHub](https://img.shields.io/badge/GitHub-000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Dente457812)
