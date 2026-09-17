# Design & Dev Squad — Memory

## Histórico de Execuções

### Run 1 — 2026-09-11
**Tarefa:** Redesign do diagrama CSAT para apresentação em reunião
**Input:** Artefato existente (v6) em https://claude.ai/code/artifact/a418fa53-3559-4fe4-913c-f150b077b7df
**Agentes ativados:** Vitor (lead), Clara (design), Pedro (implementação), Beatriz (auditoria)
**Output:** Artefato v7 publicado no mesmo URL

**Decisões de design tomadas:**
- Substituiu emoji por ícones SVG stroke-only (Heroicons style)
- Layout de duas colunas (ANTES | DEPOIS) com divisor vertical — mais editorial
- Tipografia Syne 800 para display + DM Sans para corpo (evitar Inter/Space Grotesk)
- Nodes com border-left como indicador de cor (sem fill colorido)
- Métrica como número editorial grande, sem pill genérico
- Insights numerados (01, 02, 03) em vez de dots coloridos
- Fundo escuro mantido (adequado para projetor)
- aria-hidden nos ícones decorativos

**Aprovação do usuário:** sim (confirmou rodar o squad)

### Run 3 — 2026-09-11 (iterações v13–v15, APROVADO)
**Feedback:** usuária aprovou v15
**Iterações:**
- v13: saturar cores dos nodes dim (#EEF4F8 → #C8DCEC), CSAT âmbar vivo, painel proposta #C8EAFA; remover métrica 4,85
- v14: nodes neutros PROPOSTA eram brancos (#FFF) — ficou desbalanceado; mudado para #A0CCDE
- v15: usuária pediu "mesma cor de cima e de baixo" — PROPOSTA neutral copiou exato o dim (#C8DCEC)
**Aprendizado:** nodes neutros de "antes" e "proposta" devem ter a mesma cor base; só os nodes de destaque diferenciam os fluxos

### Run 2 — 2026-09-11
**Tarefa:** Redesign completo do diagrama CSAT — layout horizontal, dados reais novos
**Input:** Usuária não aprovou layout de cards verticais; forneceu dados: 65 av. / 1.399 chamados / 4,6% / CSAT 4,85
**Output:** v12 publicado — layout horizontal (ANTES linha / PROPOSTA linha em painel azul)
**Decisões:**
- Fluxo horizontal (→) em vez de vertical — mais legível em projetor
- Métricas: 3 stats no header (1.399 chamados / 4,6% danger / 4,85 good)
- CSAT no ANTES: borda tracejada + tag vermelha "Sem engajamento"
- Fundo body: #F2F7FA; PROPOSTA painel: #DFF2FC borda #58C0DC
- Removido 1,73% (dado antigo); atualizado para 4,6% (65/1.399)

## Contexto Acumulado

- **Empresa:** Sistema RAM — Suporte
- **Usuária:** Micaelly — pt-BR, claude-code IDE
- **Estilo preferido:** visual clean para apresentações corporativas, sem elementos "cara de IA"
- **Artefato CSAT:** https://claude.ai/code/artifact/a418fa53-3559-4fe4-913c-f150b077b7df (favicon ⭐)
