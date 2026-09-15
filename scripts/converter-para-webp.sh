#!/usr/bin/env bash
# ============================================================
# converter-para-webp.sh
#
# Converte todas as imagens (.jpg/.jpeg/.png) de uma pasta de
# origem para .webp dentro de uma pasta de destino, mantendo
# o mesmo nome de arquivo (troque o nome na origem pelo SKU
# ANTES de rodar este script, se for para products/).
#
# Requer o utilitário "cwebp" (pacote webp).
#   Ubuntu/Debian: sudo apt install webp
#   macOS (Homebrew): brew install webp
#
# Uso:
#   ./converter-para-webp.sh <pasta_origem> <pasta_destino> [qualidade 0-100]
#
# Exemplo:
#   ./converter-para-webp.sh ~/fotos-produtos/originais ./products 82
# ============================================================

set -euo pipefail

ORIGEM="${1:-}"
DESTINO="${2:-}"
QUALIDADE="${3:-82}"

if [[ -z "$ORIGEM" || -z "$DESTINO" ]]; then
  echo "Uso: $0 <pasta_origem> <pasta_destino> [qualidade 0-100]"
  exit 1
fi

if ! command -v cwebp >/dev/null 2>&1; then
  echo "Erro: 'cwebp' não encontrado. Instale o pacote 'webp' antes de continuar."
  echo "  Ubuntu/Debian: sudo apt install webp"
  echo "  macOS (Homebrew): brew install webp"
  exit 1
fi

mkdir -p "$DESTINO"

total=0
convertidos=0
falhas=0

shopt -s nullglob nocaseglob
for arquivo in "$ORIGEM"/*.jpg "$ORIGEM"/*.jpeg "$ORIGEM"/*.png; do
  total=$((total + 1))
  nome_base="$(basename "${arquivo%.*}")"
  saida="$DESTINO/${nome_base}.webp"

  if cwebp -quiet -q "$QUALIDADE" "$arquivo" -o "$saida"; then
    convertidos=$((convertidos + 1))
    echo "OK   $(basename "$arquivo") -> $(basename "$saida")"
  else
    falhas=$((falhas + 1))
    echo "FALHOU  $(basename "$arquivo")"
  fi
done
shopt -u nullglob nocaseglob

echo ""
echo "-------------------------------------------"
echo "Total encontrado: $total"
echo "Convertidos:      $convertidos"
echo "Falhas:           $falhas"
echo "-------------------------------------------"
echo ""
echo "Lembrete: confira se cada arquivo em '$DESTINO' está nomeado"
echo "EXATAMENTE com o SKU do produto (ex.: BC-1001.webp) antes de subir."
