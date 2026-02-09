# Mock de versao (x.x.x)

Este diretorio e um modelo para criar novas versoes de migracao.

## O que vai em cada arquivo
- `script_pre.sql`: coisas que precisam existir ANTES das tabelas principais.
  - extensoes
  - schemas
  - tipos, funcoes ou enums base

- `script_pos.sql`: coisas que precisam existir DEPOIS das tabelas principais.
  - seeds iniciais
  - backfills
  - indices e views
  - ajustes de performance

## Como usar
1. Copie `x.x.x` para a versao real (ex.: `0.0.2`).
2. Preencha `script_pre.sql` e `script_pos.sql` com o que a versao exige.
