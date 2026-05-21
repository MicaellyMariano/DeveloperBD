# RelatoriosCEM — Relatórios Firebird 2.5 → HTML / PDF

Programa que conecta ao banco `CEM.FDB` e exporta qualquer relatório
como HTML estilizado que abre no Chrome/Edge → Imprimir → Salvar como PDF.

**Não precisa de Delphi. Não precisa de licença paga.**

---

## Como usar (passo a passo)

### Passo 1 — Instalar Python (só uma vez, gratuito)

1. Acesse **https://python.org/downloads**
2. Clique no botão amarelo "Download Python 3.x.x"
3. **IMPORTANTE:** na tela do instalador, marque a opção
   **"Add Python to PATH"** antes de clicar em Install Now
4. Finalize a instalação

### Passo 2 — Criar o EXE (só uma vez)

1. Abra a pasta **`delphi-relatorios\`**
2. Dê duplo clique em **`INSTALAR_E_CRIAR_EXE.bat`**
3. Aguarde (pode demorar 1-2 minutos na primeira vez)
4. Quando terminar, a pasta **`dist\`** vai abrir automaticamente
5. Dentro de `dist\` estará o arquivo **`RelatoriosCEM.exe`**

> Copie o `RelatoriosCEM.exe` para onde quiser. Ele é autossuficiente.

### Passo 3 — Usar o programa

1. Abra o **`RelatoriosCEM.exe`**
2. Clique em **Conectar** (o banco e senha já vêm preenchidos)
3. Selecione o relatório desejado
4. Preencha as datas e parâmetros
5. Clique em **▶ Gerar Relatório**
6. Clique em **⬇ Exportar HTML / PDF** → relatório abre no navegador
7. No navegador: **Ctrl + P** → **Salvar como PDF**

---

## Não quer criar o EXE agora?

Se Python já estiver instalado e a biblioteca `fdb` instalada, você pode
rodar diretamente:

- Duplo clique em **`EXECUTAR_COM_PYTHON.bat`**

---

## Relatórios disponíveis

| # | Nome | Parâmetros |
|---|------|-----------|
| 1 | Pedidos por Cliente | Data Início, Data Fim, Empresa |
| 2 | Lista de Produtos | Empresa |
| 3 | Financeiro por Período | Data Início, Data Fim, Empresa |
| 4 | Compra Estoque (Abaixo do Mínimo) | Empresa |
| 5 | Estoque Físico vs Disponível | Empresa |
| 6 | Vendas por Horário (60 dias) | Empresa |
| 7 | Entregas CT-e por Destinatário | Data Início, Data Fim, Empresa, Cód. Remetente, Cidade |
| 8 | Vendas por Dia e Hora | Data Início, Data Fim |

---

## Problemas comuns

**"Python não encontrado no PATH"**
→ Reinstale o Python marcando **"Add Python to PATH"**.

**"Erro de conexão: connection rejected"**
→ Verifique se o serviço Firebird está rodando:
  Pesquise "Serviços" no Windows → procure "Firebird Server" → Iniciar.

**"unavailable database"**
→ Confirme o caminho do `.FDB` no campo Banco.
  Desconecte o arquivo no IBExpert antes de abrir no programa.

**O EXE não abre / fecha na hora**
→ Rode `EXECUTAR_COM_PYTHON.bat` para ver a mensagem de erro no terminal.

---

## Adicionar novos relatórios

Edite o arquivo `relatorios_cem.py` e adicione um novo item à lista
`RELATORIOS` seguindo o mesmo padrão dos existentes. Depois rode
`INSTALAR_E_CRIAR_EXE.bat` novamente para gerar o EXE atualizado.
