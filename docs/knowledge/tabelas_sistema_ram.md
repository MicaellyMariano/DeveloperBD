# Tabelas do Sistema RAM

## Principais tabelas

| Tabela | Descrição |
|--------|-----------|
| `PRODUTOS` | Cadastro de produtos. Campos: CODIGO, DESCRICAO, DISPONIVEL (Sim/Não), TIPO, PECA, FATOR, UNIDADE, QTDATUAL, MOVIMENTAESTOQUE |
| `ESTOQUE` | Histórico de movimentações. Campos: CODIGO, CODPROD, DATA, TIPO (E/S), QUANTIDADE, SALDO, CLASSIFICACAO, ORIGEM, CODORIGEM |
| `PEDIDOS` | Pedidos de compra/venda. Campos: CODIGO, TIPO (E=entrada, S=saída, V=venda), DATAEMISSAO, TOTALPEDIDO, TIPOVENDA, FINANCEIRO, IDCAIXA |
| `REFS` | Registros financeiros. Campos: CODIGO, PARCELA, TIPOVENDA, VALOR, DATA_EMISSAO, DATA_VENC, DATA_PGTP, DATA_BAIXA, IDCAIXA |
| `MOVIMENT` | Movimentos de caixa. Campos: CODIGO, PARCELA, TIPOVENDA, VALOR, FLUXO (1=entrada, 2=troco/saída), DATA_PATO, IDCAIXA |
| `CONTROLECAIXA` | Cabeçalho do caixa. Campos: CODIGO, DATA, DATAFECHAMENTO, TROCO, USUARIO, HORARIO_I, HORARIO_F |
| `CONTROLECAIXA_ITENS` | Totais por forma de pagamento no fechamento. Campos: CODIGO (=id caixa), CODEMP, DESCRICAO (forma pgto), VALOR, VALOR_SISTEMA |
| `TAB_PAGAMENTOS_PEDIDO` | Split de pagamento por pedido. Campos: PEDIDO, TIPOVENDA, VALOR, PARCELA, COD_TPVENDA |
| `ITENSTABELAPRECO` | Itens da tabela de preço. Campos: CODIGO (=tabela), CODEMP, CODPROD, PRECO, PRECOBASE |
| `TABELADEPRECO` | Cabeçalho tabela de preço. TIPOPRECO=2 e MARKUP=15 para TABELA ATACADO |
| `ESTOQUE_LOTE` | Controle de lote. Só movimenta se "controlar lote" ativo no status do produto |
| `TIPO_PRODUTO` | Opções do dropdown TIPO em PRODUTOS. Sem FK com PRODUTOS — pode estar vazia |
| `NOTA` | Notas fiscais. NF_TIPO=1 (entrada), NF_TIPO=2 (saída), NF_MODELO='65' (NFC-e), '55' (NF-e) |

## Observações importantes

- `PRODUTOS.QTDATUAL` pode ficar desatualizado se trigger ausente; tela lê `ESTOQUE.SALDO`
- `PEDIDOS.TIPOVENDA='VARIOS'` = pedido com múltiplas formas de pagamento
- `PEDIDOS.FINANCEIRO` = código que liga ao MOVIMENT e REFS
- `MOVIMENT.FLUXO=1` = entrada de caixa; `FLUXO=2` = troco/saída
- `CONTROLECAIXA_ITENS` não tem coluna IDCAIXA — usa CODIGO como FK para CONTROLECAIXA
