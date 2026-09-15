#!/usr/bin/env bash
# ============================================================
# upload-em-lotes.sh
#
# Adiciona, commita e envia (push) os arquivos novos/alterados
# do repositório em lotes, para evitar um único push gigante
# com milhares de imagens.
#
# Rode este script na RAIZ do repositório já clonado, depois
# de já ter colocado as imagens dentro das pastas certas
# (products/, categories/, home/, etc.).
#
# Uso:
#   ./scripts/upload-em-lotes.sh [tamanho_do_lote] [branch]
#
# Exemplo:
#   ./scripts/upload-em-lotes.sh 300 main
# ============================================================

set -euo pipefail

LOTE="${1:-300}"
BRANCH="${2:-main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Erro: rode este script dentro de um repositório git (na raiz)."
  exit 1
fi

# Lista todos os arquivos novos ou modificados, ainda não commitados,
# separados por NUL (seguro para nomes de arquivo com espaços/acentos).
mapfile -d '' -t ARQUIVOS < <(git status --porcelain -z | grep -zaE '^( M|\?\?|A )' | cut -z -c4-)

TOTAL=${#ARQUIVOS[@]}

if [[ "$TOTAL" -eq 0 ]]; then
  echo "Nenhum arquivo novo ou modificado encontrado. Nada a fazer."
  exit 0
fi

echo "Total de arquivos a enviar: $TOTAL"
echo "Tamanho de cada lote: $LOTE"
echo "Branch de destino: $BRANCH"
echo ""

NUM_LOTES=$(( (TOTAL + LOTE - 1) / LOTE ))
lote_atual=0
i=0

while [[ $i -lt $TOTAL ]]; do
  lote_atual=$((lote_atual + 1))
  fim=$((i + LOTE))
  if [[ $fim -gt $TOTAL ]]; then
    fim=$TOTAL
  fi

  echo "==> Lote $lote_atual de $NUM_LOTES (arquivos $((i+1)) a $fim)"

  # git add só dos arquivos deste lote
  for (( j=i; j<fim; j++ )); do
    git add -- "${ARQUIVOS[$j]}"
  done

  git commit -m "feat: adiciona lote de imagens ($((i+1)) a $fim de $TOTAL)"
  git push origin "$BRANCH"

  echo "Lote $lote_atual enviado com sucesso."
  echo ""

  i=$fim
done

echo "Todos os $NUM_LOTES lotes foram enviados com sucesso."
