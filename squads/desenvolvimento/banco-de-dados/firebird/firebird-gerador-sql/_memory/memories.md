# Squad Memory — GeradorSQL Firebird 2.5

## Banco de Dados
- **Arquivo:** C:\Users\ram\Documents\Bases_clientes_gerador\CEM.FDB
- **Versão Firebird:** 2.5
- **Ferramenta:** IBExpert
- **Linguagem da aplicação:** Delphi (FireDAC)
- **Credenciais padrão:** SYSDBA / masterkey
- **isql.exe:** C:\Program Files\Firebird\Firebird_2_5\bin\isql.exe
- **Total de tabelas:** 559 tabelas de usuário

## ⚠️ Operação Multi-Cliente
- O arquivo é **sempre** `CEM.FDB` no mesmo caminho
- O conteúdo muda conforme o cliente carregado (a usuária renomeia os arquivos)
- **Regra:** ao iniciar trabalho em cliente novo → rodar diagnóstico de contagem antes de qualquer SQL
- Módulos ativos variam por cliente (compras, estoque filial, NF-e, etc.)
- As contagens e módulos ativos documentados abaixo são do **cliente atual** — não são universais

## Padrões de Nomenclatura Identificados
- **Multi-empresa:** CODEMP presente em praticamente todas as tabelas (ERP multi-filial)
- **NF:** campos prefixados com `NF_` (ex: NF_NUMERO, NF_EMISSAO, NF_CFOP)
- **Tabelas de itens:** prefixo `ITENS` (ITENSNF, ITENSCOMP, ITENSMOV)
- **Tabelas de cadastro:** prefixo `CAD_` ou `CAD` (CADUSER, CADCONDICAOPAGTO)
- **Tabelas de configuração:** prefixo `CONFIG` (CONFIG, CONFIGCOMPRA, CONFIG_GRIDS)
- **Tabelas de log:** prefixo `LOG_` (LOG_RAM, LOG_PRECOS, LOGUSUARIO)
- **Tabelas fiscais:** TABELANCM, TABELAISENCAO, CCLASSTRIB, CFOP, REGRAIMP
- **Tabelas de tabela de preço:** `TABELADEPRECO`, `TABELAPRECO`, `ITENSTABELAPRECO`

## Classificação por Domínio de Negócio

### Vendas / Pedidos
- **PEDIDOS** (203 campos) — pedido de venda principal
  - PK: CODIGO + CODEMP
  - Campos-chave: CODCLI, DATAEMISSAO, TIPOVENDA, CANCELADO, STATUS, NFGERADA
  - Totais: BRUTO, LIQUIDO, TOTALPEDIDO, VALORNF
  - Fiscal: ICMS, BASEICMS, PIS, COFINS, VALORIPI, VALORST
  - NF-e: CHAVE, PROTOCOLO, MODELO, SERIE, MOTIVO, SAT_STATUS
  - XML: ENVIO_XML, XML_ENTRADA
- **PEDIDOSNF** — relação pedido x NF
- **STATUSPEDIDO** (69 campos) — controle de status detalhado
- **HIST_PED** (17 campos) — histórico de pedidos

### Fiscal / Nota Fiscal
- **NOTA** (219 campos) — nota fiscal emitida
  - PK: NF_NUMERO + CODEMP
  - Campos-chave: NF_EMISSAO, NF_SAIDA, NF_CODCLI, NF_CFOP, NF_MODELO, NF_SERIE
  - Valores: NF_BASECALC, NF_ICMS, NF_ICMSSUB, NF_VALIPI, NF_FRETE
  - Transporte: NF_CODTRANSPORT, NF_PLACATRANSPORT, NF_UFTRANSPORT
  - Parcelamento: NF_PRAZO1..8, NF_VENCIMENTO1..8, NF_VALOR1..8
  - Vinculo: NF_PEDIDO → PEDIDOS.CODIGO
- **ITENSNF** (21 campos) — itens da NF
  - PK: CODIGO + CODEMP + CODPROD
  - Campos: VALORPROD, REDUCAO, VALORICMS, VALORIPI, BASEST, VALORICMSST, QTD, VALUNITARIO
- **CFOP** (27 campos) — tabela de CFOPs
  - PK: CFCOD
- **TABELANCM** (27 campos) — tabela NCM
- **CCLASSTRIB** (20 campos) — classificação tributária
- **REGRAIMP** (23 campos) — regras de impostos
- **TABELAISENCAO** (33 campos) — isenções fiscais
- **XML_NFE_CTE** (15 campos) — XMLs de NF-e e CT-e

### Clientes / Fornecedores
- **CADASTRO** (309 campos) — cadastro principal
  - PK: CODIGO + CODEMP
  - Campos: NOMFANT, NOMRAZ, CNPJ, INSC, FONE, CELULAR, TIPOCAD, CIDADE, UF, CEP

### Produtos / Estoque
- **PRODUTOS** (338 campos) — cadastro de produtos
  - PK: CODIGO + CODEMP
  - Campos-chave: CODBARRA, DESCRICAO, CLASS, SITU, DISPONIVEL, QTDATUAL, SALDOMINIMO
  - Preços: PRECOPRAZO, PRECONF, LUCRO
  - Fiscal: ICMS, IPI, COFINS, PIS, IVA, CFOP, EAN
- **ESTOQUE** (32 campos)
  - PK: CODIGO + CODEMP + CODPROD
- **ESTOQUEF** (32 campos) — estoque por filial
- **AJUSTEESTOQUE** (15 campos)
- **TABELADEPRECO** (22 campos)

### Financeiro
- **MOVIMENT** (24 campos) — movimentações financeiras
  - PK: SEQUENCIA + CODEMP + PARCELA + CODIGO
- **ITENSMOV** (15 campos) — itens de movimentação
- **BANCO** (57 campos) — contas bancárias/boleto
  - PK: CODIGO + CODEMP
  - PIX: TIPOCHAVEPIX, CHAVEPIX
  - Boleto: NOSSO_NUMERO, NUM_REMESSA, CARTEIRA
- **PARCELAS** (15 campos)
  - PK: CODIGO + CODEMP + CODPED
- **CONTROLECAIXA** (18 campos)
  - PK: CODIGO + CODEMP
- **HISTFIN** (13 campos) — histórico financeiro

### Compras
- **COMPRA** (42 campos)
  - PK: CODIGO + CODEMP + COTACAO
- **ITENSCOMP** (23 campos) — itens de compra
- **SOLICITACAO_COMPRA** (20 campos)

### Empresa / Configuração
- **EMPRESA** (235 campos) — dados da empresa/filial
  - PK: CODIGO + NETCOD
- **CONFIG** (525 campos) — configurações do sistema
- **CADUSER** (405 campos) — usuários do sistema

### XML / MDF-e / CT-e
- **XML_NFE_CTE** (15 campos) — XMLs
- **MDFE** (72 campos) — MDF-e
- **CTE** (5 campos) — CT-e

## Regras de Negócio Descobertas (SQLs Reais)

### SQL-001 — Relatório Pedidos por Cliente (fonte: Catito)
**Propósito:** Agrupa pedidos de venda por cliente com total de pedidos e valor no período.

**ITENSPAD** — É a tabela de itens dos PEDIDOS (não ITENSNF!)
- Join: `ITENSPAD.codigo = PEDIDOS.codigo AND ITENSPAD.codemp = PEDIDOS.codemp`
- Campo de valor do item: `ITENSPAD.totalitem` — valor total do item no pedido
- Esta é a tabela correta para somar valores de pedidos (não ITENSNF, que é para NF)

**Filtros obrigatórios para pedidos de venda ativos:**
- `PEDIDOS.tipo = 'S'` — tipo 'S' identifica pedido de saída/venda (não orçamento, transferência, etc.)
- `PEDIDOS.aprovado = 1` — somente pedidos aprovados
- `PEDIDOS.cancelado` — campo inconsistente: pode conter 'Não', NULL ou '0' para não cancelado
  - Sempre usar: `(cancelado = 'Não' OR cancelado IS NULL OR cancelado = '0')`
- `PEDIDOS.classpedido = 'Venda'` — classificação do pedido; filtra somente vendas
  - Outros valores possíveis: 'Orçamento', 'Transferência', etc.
- `PEDIDOS.codemp IN (1)` — filtro de empresa (sistema multi-empresa)

**CADASTRO** — usado como clientes
- `CADASTRO.nomfant` = nome fantasia do cliente
- `CADASTRO.municipio` = cidade do cliente
- Join: `CADASTRO.codigo = PEDIDOS.codcli`

**Relacionamentos confirmados:**
- `PEDIDOS.codigo + PEDIDOS.codemp` → `ITENSPAD.codigo + ITENSPAD.codemp` (itens do pedido)
- `PEDIDOS.codcli` → `CADASTRO.codigo` (cliente)

### SQL-009 — Movimentação Diária de Estoque (fonte: sistema)
**Propósito:** Lista todos os registros de movimentação do estoque de um dia específico.

**ESTOQUE — natureza da tabela confirmada:**
- NÃO é uma tabela de saldo único por produto — é um **log de movimentações**
- Cada linha = um evento de movimentação com data e saldo resultante
- `DATA` = data da movimentação (campo DATE, filtro direto: `DATA = :DATA`)
- `codigo` = código de ordenação do registro
- Saldo atual de um produto = FIRST 1 saldo ORDER BY data DESC, tipo DESC, ordem DESC
- Para relatório de movimentações de um dia: filtrar `DATA = :DATA` diretamente

---

### SQL-008 — Produtos Disponíveis CST 020 (fonte: sistema)
**Propósito:** Lista produtos ativos com situação tributária CST 020.

**PRODUTOS.situ** — código de situação tributária (CST/CSOSN) do produto
- Valor: `'020'` = CST 020 (tributado com redução de base de cálculo - ICMS)
- Campo texto com zero à esquerda (sempre 3 dígitos: '020', '040', '060', etc.)
- Representa o CST/CSOSN padrão do produto para fins de NF-e

**Resumo dos campos de PRODUTOS confirmados até agora:**
- `codigo` — PK
- `descricao` — descrição
- `unidade` — unidade de medida
- `disponivel` — `'Sim'` / `'Não'` (string)
- `codbarra` — código de barras unitário
- `codbarras_cx` — código de barras da caixa
- `est_saldo` — saldo físico desnormalizado
- `saldominimo` — saldo mínimo para reposição
- `precocusto` — preço de custo
- `precominimo` — preço mínimo de venda
- `conta_contabil` — responsável/colaborador pelo produto
- `classificacao` — FK para CLASSCOMERCIAL.CODIGO
- `situ` — CST/CSOSN tributário (ex: '020', '040', '060')

---

### SQL-007 — Estoque Físico x Disponível (fonte: sistema)
**Propósito:** Calcula saldo disponível real descontando itens já reservados em pedidos em separação.

**PRODUTOS.est_saldo** — campo DESNORMALIZADO de saldo físico
- Existe diretamente em PRODUTOS como campo pré-calculado
- Dois padrões de saldo existem no sistema:
  1. **Rápido:** `produtos.est_saldo` — campo direto, pode estar desatualizado
  2. **Preciso:** `SELECT FIRST 1 saldo FROM ESTOQUE WHERE codprod=? ORDER BY data DESC, tipo DESC, ordem DESC`
- Para relatórios simples: usar `produtos.est_saldo`
- Para precisão máxima: usar subquery no ESTOQUE

**ITENSPAD — campos novos confirmados:**
- `codprod` — FK para PRODUTOS.CODIGO (produto do item do pedido) ← campo novo confirmado
- `qtd` — quantidade do item no pedido
- Relações completas de ITENSPAD:
  - `itenspad.codigo = pedidos.codigo` → pedido ao qual pertence
  - `itenspad.codemp = pedidos.codemp` → empresa
  - `itenspad.codprod` → produto do item

**PEDIDOS.status** — campo de status detalhado com valores textuais
- Exemplos de valores: `'2 - EM SEPARAÇÃO'` (pedido em separação/picking)
- Padrão: número + descrição concatenados (ex: '1 - AGUARDANDO', '2 - EM SEPARAÇÃO', '3 - ENTREGUE')
- Diferente de `cancelado` — são campos independentes

**PEDIDOS.cancelado** — padrão de cancelamento atualizado:
- `'Sim'` = cancelado
- `'Não'` ou NULL = não cancelado
- Padrão seguro: `COALESCE(pe.cancelado, 'Não') <> 'Sim'`

**Conceito de Saldo Disponível:**
```sql
saldo_disponivel = produtos.est_saldo
                 - SUM(itenspad.qtd) dos pedidos em status '2 - EM SEPARAÇÃO' não cancelados
```
- `reserva.total_prometido` = total de itens já comprometidos em separação
- Usar COALESCE(..., 0) para produtos sem reservas

**Relacionamentos novos confirmados:**
- `ITENSPAD.codprod` → `PRODUTOS.codigo` (produto do item)

---

### SQL-006 — Município Origem CT-e (fonte: sistema)
**Propósito:** Lista CT-e autorizados filtrando por município de origem, com chave de acesso e dados fiscais.

**NOTA — campos novos confirmados:**
- `nf_numero` — número interno da NF/CT-e
- `nf_cfop` — CFOP da nota
- `nfe` — número da NF-e/CT-e (número de sequência externo)
- `nf_emissao` — data de emissão (filtro: `>= '2025/01/01'`)
- `nf_codcli` — FK para CADASTRO.CODIGO (emitente/destinatário)
- `chave` — chave de acesso da NF-e/CT-e (44 dígitos). Padrão de exibição: `'A.'||n.chave`
- `motivo` — situação/motivo SEFAZ. Ex: `'Autorizado o uso do CT-e'`, 'Rejeitado', 'Cancelado'
- `nf_valprod` — valor dos produtos
- `nf_valnota` — valor total da nota
- `nf_modelo` — modelo do documento: NULL = NF-e comum, `'CTe'` = CT-e
- `ini_municipio` — município de **origem** do CT-e (início da prestação de serviço)
- `codemp` — empresa emissora

**NOTAPROD** — notas de produtos vinculadas à NOTA
- Join: `notaprod.codemp = nota.codemp AND notaprod.nf_numero = nota.nf_numero`
- Complementa dados da nota (produtos vinculados ao CT-e)

**Filtros para CT-e autorizados:**
- `nf_modelo = 'CTe'` — somente CT-e (ou NULL para NF-e)
- `motivo = 'Autorizado o uso do CT-e'` — somente autorizados pela SEFAZ
- `ini_municipio LIKE '%' || :MUNICIPIO || '%'` — filtro parcial por município

**Relacionamentos confirmados:**
- `NOTA.nf_numero + NOTA.codemp` → `NOTAPROD.nf_numero + NOTAPROD.codemp`
- `NOTA.nf_codcli` → `CADASTRO.codigo`

---

### SQL-005 — Vendas Denise (fonte: sistema)
**Propósito:** Lista pedidos de um operador/vendedor específico no período, com dados de caixa e NF vinculada.

**PEDIDOS — campos novos confirmados:**
- `tipovenda` — tipo de venda (ex: 'Balcão', 'Delivery', 'Crédito')
- `origem` — origem do pedido (ex: 'APP', 'PDV', 'Sistema', canal de venda)
- `idcaixa` — ID do caixa vinculado ao pedido (NOT NULL = pedido passou pelo caixa)
- `notaf` — número da NF fiscal vinculada ao pedido
- `totalpedido` — valor total do pedido
- `criado` — **nome do operador/usuário que criou o pedido** (campo texto, não FK)
  - Filtro: `criado = 'DENISE'` — nome em maiúsculas
- `dataemissao` — data de emissão do pedido

**Padrão aprendido:**
- `idcaixa IS NOT NULL` = pedido que passou pelo PDV/caixa (faturado no ponto de venda)
- `criado` é o nome do operador (string), não um código. Sempre usar em MAIÚSCULAS.
- Sem filtro `tipo = 'S'` ou `classpedido = 'Venda'` — este SQL captura todos os tipos do operador

---

### SQL-004 — Compra Estoque por Colaborador (fonte: sistema)
**Propósito:** Lista produtos abaixo do saldo mínimo para reposição, filtrados por colaborador responsável.

**ESTOQUE — campos confirmados (padrão de saldo atual):**
- `codprod` — FK para PRODUTOS.CODIGO
- `codemp` — empresa
- `saldo` — saldo atual em estoque ← campo real de saldo
- `data` — data do registro de estoque
- `tipo` — tipo do movimento de estoque
- `ordem` — ordem do registro
- **Padrão para saldo atual (sempre usar este subquery):**
  ```sql
  (SELECT FIRST 1 saldo FROM ESTOQUE
   WHERE estoque.codprod = produtos.codigo AND estoque.codemp = :CODEMP
   ORDER BY data DESC, tipo DESC, ordem DESC)
  ```
  ⚠️ ESTOQUE tem múltiplos registros por produto. O saldo atual é sempre o FIRST 1 ordenado por data DESC, tipo DESC, ordem DESC.

**PRODUTOS — campos novos confirmados:**
- `PRECOCUSTO` — preço de custo do produto
- `PRECOMINIMO` — preço mínimo de venda
- `CONTA_CONTABIL` — **campo usado como "colaborador/responsável"** pelo produto
  - Apesar do nome sugerir conta contábil, é usado aqui como identificador do colaborador/comprador responsável pelo produto
- `DISPONIVEL = 'Sim'` — produto disponível (valor string 'Sim', não inteiro!)
- `classificacao` — FK para CLASSCOMERCIAL.CODIGO (classificação comercial do produto)

**CLASSCOMERCIAL** — classificação comercial dos produtos
- `codigo` — PK (referenciado por PRODUTOS.classificacao)
- `nome` — nome da classificação comercial

**TABELAMARCAS** — vínculo produto x marca
- Join: `tabelamarcas.codprod = produtos.codigo AND tabelamarcas.codemp = produtos.codemp`
- Usada para enriquecer listagem de produtos com marca

**Lógica de QTDCOMPRAR:**
```sql
CAST((produtos.SALDOMINIMO - saldo_atual) AS NUMERIC(15,2)) AS QTDCOMPRAR
```
Quantidade a comprar = saldo mínimo menos saldo atual (quando negativo = produto em falta)

**Filtro de produtos para reposição:**
- `produtos.saldominimo NOT IN (0)` — só produtos que têm saldo mínimo definido
- `saldo_atual < produtos.saldominimo` — saldo atual abaixo do mínimo
- `produtos.DISPONIVEL = 'Sim'` — somente ativos

**Relacionamentos confirmados:**
- `PRODUTOS.classificacao` → `CLASSCOMERCIAL.codigo`
- `PRODUTOS.codigo + PRODUTOS.codemp` → `TABELAMARCAS.codprod + TABELAMARCAS.codemp`

---

### SQL-003 — Financeiro por Período (fonte: sistema)
**Propósito:** Relatório de movimentações financeiras liquidadas no período, com classificação e valor de fluxo de caixa.

**REFS** — tabela principal de contas a receber/pagar (lançamentos financeiros)
- `codigo` — código do lançamento
- `parcela` — número da parcela
- `codemp` — empresa
- `valor` — valor do lançamento
- `fluxo` — direção do fluxo: **1 = entrada (crédito)**, outro valor = saída (débito)
  - Padrão: `CASE WHEN refs.fluxo = 1 THEN refs.valor ELSE (refs.valor * -1) END`
- `cod_class` — FK para TIPOPLAN.CODIGO (classificação financeira / plano de contas)
- `COD_CLI` — FK para CADASTRO.CODIGO (cliente/fornecedor do lançamento)
- `TIPOVENDA` — tipo de venda vinculado ao lançamento
- `cancelado` — 'Não' ou NULL = não cancelado
- `previsao` — 0 ou NULL = lançamento real (não previsão). Previsões têm previsao = 1
- `agrupado` — 'Não', NULL ou '' = não agrupado (bordero, etc.)
- `caixa` — FK para CAIXA.CODIGO (conta/caixa do lançamento)
- `data_venc` — data de vencimento

**MOVIMENT** — tabela de liquidações/pagamentos (baixas financeiras)
- `codigo` + `parcela` + `codemp` — chave de join com REFS
- `data_liq` — **data de liquidação** (data que o pagamento/recebimento foi efetivado)
- ⚠️ INNER JOIN REFS → MOVIMENT = somente lançamentos **já liquidados (pagos/recebidos)**
- LEFT JOIN REFS → MOVIMENT = todos os lançamentos (pagos + em aberto)

**TIPOPLAN** — plano de contas financeiro (classificação)
- `codigo` — PK (referenciado por REFS.cod_class)
- `nome` — nome da classificação financeira (ex: "Vendas", "Despesas", "Fornecedores")

**CAIXA** — contas/caixas financeiros
- `codigo` — PK
- `encontro_contas` — flag: NULL ou 0 = caixa normal. Valores > 0 = encontro de contas (compensação)
  - Filtro padrão: `caixa.encontro_contas IS NULL OR caixa.encontro_contas = 0`

**Filtros obrigatórios para financeiro real:**
- `refs.valor > 0` — exclui lançamentos zerados
- `refs.cancelado = 'Não' OR refs.cancelado IS NULL`
- `refs.previsao = 0 OR refs.previsao IS NULL` — exclui previsões
- `refs.agrupado = 'Não' OR refs.agrupado IS NULL OR refs.agrupado = ''` — exclui agrupados
- Subquery CAIXA: exclui contas de encontro de contas

**Relacionamentos confirmados:**
- `REFS.codigo + REFS.parcela + REFS.codemp` → `MOVIMENT.codigo + MOVIMENT.parcela + MOVIMENT.codemp`
- `REFS.cod_class` → `TIPOPLAN.codigo`
- `REFS.COD_CLI` → `CADASTRO.codigo`
- `REFS.caixa` → `CAIXA.codigo`

---

### SQL-002 — Lista de Produtos (fonte: sistema)
**Propósito:** Listagem geral de produtos com última data de movimentação no estoque.

**PRODUTOS — campos confirmados:**
- `codigo` — PK do produto
- `descricao` — descrição do produto
- `unidade` — unidade de medida (ex: UN, CX, KG, LT)
- `disponivel` — flag de disponibilidade do produto (ativo/inativo)
- `codbarra` — código de barras da unidade (item individual)
- `codbarras_cx` — código de barras da **caixa** (embalagem secundária — campo diferente de codbarra)

**ESTOQUE — campos confirmados:**
- `codprod` — FK para PRODUTOS.CODIGO
- `DATA` — data da movimentação de estoque
- Subquery padrão para última movimentação: `SELECT MAX(e.DATA) FROM ESTOQUE e WHERE e.codprod = p.codigo`

**Relacionamento confirmado:**
- `ESTOQUE.codprod` → `PRODUTOS.codigo`

---

## Relacionamentos Principais Identificados (Marcos Andrade)
- PEDIDOS.CODCLI → CADASTRO.CODIGO (cliente do pedido)
- PEDIDOS.CODEMP → EMPRESA.CODIGO (empresa)
- NOTA.NF_PEDIDO → PEDIDOS.CODIGO (NF originada do pedido)
- NOTA.NF_CODCLI → CADASTRO.CODIGO (cliente da NF)
- ITENSNF.CODIGO → NOTA.NF_NUMERO (itens da NF)
- ITENSNF.CODPROD → PRODUTOS.CODIGO (produto da NF)
- ESTOQUE.CODPROD → PRODUTOS.CODIGO (estoque do produto)
- PARCELAS.CODPED → PEDIDOS.CODIGO (parcelas do pedido)
- MOVIMENT.CODIGO → CADASTRO.CODIGO (cliente do movimento financeiro)
- BANCO.CODEMP → EMPRESA.CODIGO (banco da empresa)
- NOTA.NF_CFOP → CFOP.CFCOD (código CFOP)

⚠️ NOTA: Banco não usa FK declaradas no Firebird. Relacionamentos são por convenção de nome de campo.

## Tabelas ATIVAS — Contagem Real de Registros (2026-05-11)

### Núcleo do sistema (tabelas com dados reais)
| Tabela | Registros | Papel |
|--------|-----------|-------|
| LOGUSUARIO | 589.262 | Log de ações de usuários |
| ESTOQUE | 279.262 | Log de movimentações de estoque |
| ITENSPAD | 276.464 | Itens dos pedidos ← tabela principal de itens |
| REFS | 166.226 | Contas a receber/pagar |
| MOVIMENT | 165.770 | Liquidações financeiras |
| PARCELAS | 159.849 | Parcelas dos pedidos/NFs |
| PEDIDOS | 154.509 | Pedidos de venda |
| NOTAPROD | 104.194 | Itens das NFs ← usar NOTAPROD, não ITENSNF! |
| NOTA | 56.754 | Notas fiscais emitidas |
| TABELANCM | 19.665 | Tabela NCM fiscal |
| CONTROLECAIXA_ITENS | 8.365 | Itens do controle de caixa |
| PRODUTOS | 2.387 | Cadastro de produtos |
| CONTROLECAIXA | 1.246 | Controle de caixa |
| CFOP | 446 | Tabela de CFOPs |
| TIPOPLAN | 52 | Plano de contas financeiro |
| CADASTRO | 13 | Clientes/fornecedores |
| TIPOVENDA | 7 | Tipos de venda |
| STATUSPEDIDO | 6 | Status de pedidos |

### Módulos NÃO ativos nesta instalação (0 registros)
- **ITENSNF** = 0 → ⚠️ NÃO usar para itens de NF! Usar **NOTAPROD**
- **COMPRA / ITENSCOMP** = 0 → módulo de compras não utilizado
- **ESTOQUEF** = 0 → controle de estoque por filial não usado
- **ITENSMOV / MOVIMENTOG / ITENSMOVG** = 0 → não utilizados
- **BANCO / TABELADEPRECO / TABELAMARCAS** = 0 → não configurados
- **HIST_PED / HISTFIN** = 0 → históricos não utilizados
- **SOLICITACAO_COMPRA / REGRAIMP** = 0 → não ativos

## Histórico de Execuções
- 2026-05-11 | Mapeamento completo de 559 tabelas + contagem de registros | CEM.FDB
