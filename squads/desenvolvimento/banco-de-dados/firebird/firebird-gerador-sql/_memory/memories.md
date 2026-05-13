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

### SQL-010 — Exportação Fiscal de Produtos para Excel (fonte: sistema)
**Propósito:** Extrai campos fiscais dos produtos para o escritório contábil preencher e devolver para carga no sistema.
**Uso:** Relatório → Excel → escritório preenche → reimporta atualizado no ERP.

**PRODUTOS — campos fiscais confirmados:**
- `class` — classificação do produto (FK para CLASSCOMERCIAL)
- `situ` — CST/CSOSN padrão do produto (ex: '020', '040')
- `ST` — flag/valor de Substituição Tributária
- `CST_ICMS` — código CST do ICMS do produto
- `CST_PIS` — código CST do PIS
- `CST_COFINS` — código CST do COFINS
- `CST_IPI` — código CST do IPI
- `CST_NFCE` — CST específico para NFC-e (Cupom Fiscal Eletrônico)
- `ORIGEM_CST` — origem da mercadoria (0=nacional, 1=estrangeiro importado, etc.)
- `CFOP` — CFOP padrão do produto para NF-e
- `CFOP_SAT` — CFOP específico para SAT/NFC-e
- `ST_SAT` — ST específico para SAT
- `CEST` — Código Especificador da Substituição Tributária (CEST)

**Filtro padrão:** `DISPONIVEL = 'Sim'` — somente produtos ativos

---

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
- `ini_uf` — UF de origem do CT-e
- `municipio_termino_prest` — município de **destino** do CT-e (término da prestação) ← usar para "cidade de entrega"
- `nf_municipiotransport` — município do transportador
- `codemp` — empresa emissora

**NOTAPROD** — notas de produtos vinculadas à NOTA
- **LEFT JOIN** `notaprod.codemp = nota.codemp AND notaprod.nf_numero = nota.nf_numero`
- Complementa dados da nota (produtos vinculados ao CT-e)
- LEFT JOIN = retorna a NF mesmo sem itens em NOTAPROD

**CADASTRO** — join via LEFT JOIN para CT-e
- **LEFT JOIN** `cadastro.codigo = nota.nf_codcli`
- `CADASTRO.nomraz` = razão social (confirmado neste contexto de CT-e)
- `CADASTRO.cnpj` = CNPJ do emitente/destinatário

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

### SQL-012 — Entregas CT-e por Cidade, Remetente e Destinatário (fonte: sistema)
**Propósito:** Relatório da transportadora mostrando todas as entregas por cidade, com remetente (quem enviou) e destinatário (quem recebeu). Filtros opcionais por cidade e código do remetente.

**Estrutura do CT-e na NOTA confirmada:**
- `nf_codcli` = **DESTINATÁRIO** (quem recebeu a mercadoria = cliente do cliente)
- `cod_remetente` = **REMETENTE** (quem enviou = cliente da transportadora)
- `cod_tomador` = quem paga o frete (pode ser remetente ou destinatário)
- `tomador` = campo texto: `'Remetente'` ou `'Destinatário'` — indica quem paga
- `municipio_termino_prest` = cidade de **destino** (onde foi entregue)
- `ini_municipio` = cidade de **origem** (de onde saiu)
- `ini_uf` = UF de origem

⚠️ `nf_codcli` em CT-e = DESTINATÁRIO, não o cliente que contratou o transporte!
⚠️ Para filtrar pelo cliente da transportadora, usar `cod_remetente`, não `nf_codcli`

**Cidades gravadas SEM acento nesta base:**
- `BRAGANCA PAULISTA`, `HORTOLANDIA`, `JAGUARIUNA`, `SUMARE`, etc.
- Busca por cidade: usar `CONTAINING` (case-insensitive, sem wildcards manuais)

**Padrão para parâmetros opcionais em Firebird 2.5:**
- String vazia como "sem filtro": `CAST(:CIDADE AS VARCHAR(100)) = '' OR campo CONTAINING CAST(:CIDADE AS VARCHAR(100))`
- Inteiro zero como "sem filtro": `:CODCLI = 0 OR campo = :CODCLI`
- ⚠️ NUNCA usar `:PARAM IS NULL` → erro "Unknown SQL Data type (32766)"
- ⚠️ NUNCA usar LIKE com parâmetro sem CAST → erro "string right truncation"
- ✅ Sempre usar `CAST(:PARAM AS VARCHAR(N))` em filtros com LIKE/CONTAINING

**Campos de valor do CT-e na NOTA:**
- `FRETE_VALOR` — ✅ valor do frete (campo correto para CT-e). `NF_FRETE` é NULL em CT-e!
- `VALOR_CARGA` — valor total da carga transportada
- `NF_VALNOTA` — valor total da nota CT-e
- `VAL_PEDAGIO` — valor de pedágio (geralmente NULL)
- `VAL_SEGURO_CARGA` — valor do seguro da carga
- `OUTROS_VALORES` — outros valores cobrados
- `UF_TERMINO_PREST` — UF de destino do CT-e

⚠️ `NF_FRETE` é NULL em CT-e — usar sempre `FRETE_VALOR` para valor do frete em CT-e

**SQL-012a — Detalhe por CT-e (com data e número para identificar no sistema):**
```sql
SELECT
    n.nf_emissao                                          AS data_emissao,
    n.nfe                                                 AS numero_cte,
    COALESCE(n.municipio_termino_prest, 'NAO INFORMADO') AS cidade_entrega,
    COALESCE(rem.nomraz, 'NAO IDENTIFICADO')             AS remetente,
    COALESCE(dest.nomraz, 'NAO IDENTIFICADO')            AS destinatario,
    n.nf_valnota                                         AS valor
FROM nota n
LEFT JOIN cadastro rem  ON rem.codigo  = n.cod_remetente
LEFT JOIN cadastro dest ON dest.codigo = n.nf_codcli
WHERE n.nf_numero IS NOT NULL
  AND n.nf_modelo = 'CTe'
  AND n.nf_emissao >= :DATA_INI
  AND n.nf_emissao <= :DATA_FIM
  AND n.codemp IN (:CODEMP)
  AND n.motivo = 'Autorizado o uso do CT-e'
  AND (COALESCE(CAST(:CIDADE AS VARCHAR(100)), '') = '' OR n.municipio_termino_prest CONTAINING CAST(:CIDADE AS VARCHAR(100)))
  AND (:CODCLI = 0 OR n.cod_remetente = :CODCLI)
ORDER BY n.nfe
```

**SQL-012b — "Entregas por Destinatário e Cidade — CT-e" (versão final aprovada pelo cliente):**
- Remetente obrigatório (`:CODCLI`)
- Cidade opcional — vazio retorna todas, digitando parte do nome filtra
- Sem campo de frete (cliente não precisava)
- `LIST()` para mostrar números dos CT-e na linha agrupada

```sql
SELECT
    COALESCE(rem.nomraz, 'NAO IDENTIFICADO')             AS remetente,
    COALESCE(n.municipio_termino_prest, 'NAO INFORMADO') AS cidade_entrega,
    COALESCE(dest.nomraz, 'NAO IDENTIFICADO')            AS destinatario,
    COUNT(n.nf_numero)                                    AS qtd_entregas,
    SUM(n.nf_valnota)                                     AS valor_total,
    LIST(n.nfe, ', ')                                     AS numeros_cte
FROM nota n
LEFT JOIN cadastro rem  ON rem.codigo  = n.cod_remetente
LEFT JOIN cadastro dest ON dest.codigo = n.nf_codcli
WHERE n.nf_numero IS NOT NULL
  AND n.nf_modelo = 'CTe'
  AND n.nf_emissao >= :DATA_INI
  AND n.nf_emissao <= :DATA_FIM
  AND n.codemp IN (:CODEMP)
  AND n.motivo = 'Autorizado o uso do CT-e'
  AND n.cod_remetente = :CODCLI
  AND (COALESCE(CAST(:CIDADE AS VARCHAR(100)), '') = '' OR n.municipio_termino_prest CONTAINING CAST(:CIDADE AS VARCHAR(100)))
GROUP BY n.cod_remetente, rem.nomraz, n.municipio_termino_prest, n.nf_codcli, dest.nomraz
ORDER BY n.municipio_termino_prest, qtd_entregas DESC
```

**LIST() — agregação de valores em Firebird 2.5:**
- `LIST(campo, ', ')` = concatena múltiplos valores em uma célula (equivalente ao GROUP_CONCAT do MySQL)
- Exemplo: `LIST(n.nfe, ', ')` → `'42175, 42180, 42195'`
- Disponível nativamente no Firebird 2.5 — usar sempre que precisar listar IDs/números agrupados

**Padrão COALESCE para parâmetro opcional string no IBExpert:**
- IBExpert envia NULL quando o campo é deixado em branco (não string vazia!)
- ✅ Correto: `COALESCE(CAST(:PARAM AS VARCHAR(100)), '') = ''`
- ❌ Errado: `CAST(:PARAM AS VARCHAR(100)) = ''` — falha quando NULL

**Cidades disponíveis nesta base (CT-e codemp=1):**
AMERICANA, AMPARO, ARTUR NOGUEIRA, BARUERI, BRAGANCA PAULISTA, CAMPINAS, CONCHAL, COTIA, DIADEMA, EXTREMA, FORTALEZA, FRANCO DA ROCHA, GUARULHOS, HOLAMBRA, HORTOLANDIA, INDAIATUBA, ITAPECERICA DA SERRA, ITUMBIARA, ITUPEVA, JAGUARIUNA, JUNDIAI, LEME, LIMEIRA, MACEIO, MAUA, MOGI GUACU, MOGI MIRIM, MORUNGABA, NOVA ODESSA, NOVO HAMBURGO, OSASCO, PEDREIRA, RAFARD, SALTO, SANTA BARBARA D'OESTE, SANTANA DE PARNAIBA, SANTO ANDRE, SANTO ANTONIO DE POSSE, SAO BERNARDO DO CAMPO, SAO CAETANO DO SUL, SAO PAULO, SERRA NEGRA, SOROCABA, SUMARE, VALINHOS, VARGEM GRANDE PAULISTA

---

### SQL-011 — Vendas por Horário dos Últimos 60 Dias (fonte: sistema)
**Propósito:** Relatório analítico que mostra distribuição de vendas por hora do dia nos últimos 60 dias, com TOTAL consolidado via UNION.

**PEDIDOS — campos novos confirmados:**
- `DATACRIADO` — data de criação do pedido (tipo DATE). Diferente de `DATAEMISSAO` (data de emissão)
  - `DATACRIADO` = quando o pedido foi registrado no sistema
  - `DATAEMISSAO` = data de emissão oficial do pedido/faturamento
- `HORACRIADO` — hora de criação do pedido (tipo TIME: HH:MM:SS)
  - Uso: `EXTRACT(HOUR FROM pedidos.horacriado)` para agrupar por hora

**STATUS = '5 - FINALIZADO'** confirmado como valor válido de PEDIDOS.STATUS
- Padrão de valores confiramados: `'2 - EM SEPARAÇÃO'`, `'5 - FINALIZADO'`
- Formato: número + espaço + hífen + espaço + descrição maiúscula

**Padrões Firebird 2.5 para formatação de datas (sem TO_CHAR):**
```sql
-- Zero-padding manual via CASE WHEN
CASE WHEN EXTRACT(DAY FROM campo) < 10
     THEN '0' || CAST(EXTRACT(DAY FROM campo) AS VARCHAR(2))
     ELSE CAST(EXTRACT(DAY FROM campo) AS VARCHAR(2))
END
-- Formato completo DD/MM/AAAA:
CASE WHEN EXTRACT(DAY FROM d) < 10 THEN '0' ELSE '' END
|| CAST(EXTRACT(DAY FROM d) AS VARCHAR(2)) || '/'
|| CASE WHEN EXTRACT(MONTH FROM d) < 10 THEN '0' ELSE '' END
|| CAST(EXTRACT(MONTH FROM d) AS VARCHAR(2)) || '/'
|| CAST(EXTRACT(YEAR FROM d) AS VARCHAR(4))
```
- ⚠️ Firebird 2.5 NÃO tem TO_CHAR() ou FORMAT() — usar EXTRACT + CASE WHEN + concatenação

**Padrão de janela de tempo rolante:**
```sql
WHERE pedidos.datacriado >= CURRENT_DATE - 60
```
- `CURRENT_DATE - 60` = últimos 60 dias a partir de hoje (Firebird suporta aritmética de datas diretamente)
- Usar `DATACRIADO` (não DATAEMISSAO) para filtros de período de criação

**Padrão de UNION com linha de TOTAL:**
```sql
SELECT hora, qtd_pedidos, valor_total, 1 AS ORDEM, hora_num AS HORA_ORDER FROM ...
UNION ALL
SELECT 'TOTAL', COUNT(*), SUM(...), 2 AS ORDEM, 99 AS HORA_ORDER FROM ...
ORDER BY ORDEM, HORA_ORDER
```
- Técnica padrão para incluir linha de totais sem subquery: UNION ALL com coluna de ordenação artificial
- ORDEM = 1 para detalhes, ORDEM = 2 para totais garante que TOTAL aparece no final

**Filtros usados para vendas finalizadas (relatório de vendas):**
- `pedidos.status = '5 - FINALIZADO'`
- `(pedidos.cancelado = 'Não' OR pedidos.cancelado IS NULL)`
- `pedidos.codemp IN (:CODEMP)`

---

## Histórico de Execuções
- 2026-05-11 | Mapeamento completo de 559 tabelas + contagem de registros | CEM.FDB
- 2026-05-11 | SQL-011 registrado: vendas por horário, DATACRIADO/HORACRIADO, formatação de datas Firebird 2.5
- 2026-05-12 | SQL-012 registrado: CT-e transportadora — remetente/destinatário, FRETE_VALOR, CONTAINING, COALESCE para NULL em IBExpert, LIST() para concatenar CT-e na linha
