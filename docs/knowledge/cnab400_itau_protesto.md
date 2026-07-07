# CNAB 400 Itaú — Prazo de Protesto

## Posição do campo

No layout CNAB 400 do Itaú, o prazo de protesto fica em:

- **Posição:** 392-393 (1-indexed) → índice `391:393` em Python (0-indexed)
- **Tamanho:** 2 caracteres numéricos
- **Conteúdo:** número de dias para protesto

## Atenção

- `00` = sem protesto configurado → o banco pode interpretar como "protestar em 2 dias"
- Sempre verificar se o valor está correto antes de remessa

## Caso real

Arquivo CNAB estava com `00` na posição 392-393, causando protesto automático em 2 dias.
