#!/usr/bin/env bash
set -euo pipefail

# --------- CONFIG EDITÁVEL ----------
IMAGE_NAME="bit-check"
DOCKERFILE="Dockerfile"
ISSUE_URL="${ISSUE_URL:-https://github.com/bit-team/backintime/issues/2245}"
# -----------------------------------

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
ok()   { printf "✅ %s\n" "$*"; }
warn() { printf "⚠️  %s\n" "$*"; }
err()  { printf "❌ %s\n" "$*" >&2; }

section() { echo; bold "=== $* ==="; }

FAIL=0
pass() { ok "$*"; }
fail() { err "$*"; FAIL=$((FAIL+1)); }

section "1) Git remotes, branch e estado"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  REMOTES="$(git remote -v)"
  DIRTY="$(git status --porcelain)"
  echo "Branch atual: $CURRENT_BRANCH"
  echo "Remotes:"
  echo "$REMOTES" | sed 's/^/  /'
  if echo "$REMOTES" | grep -q 'upstream.*bit-team/backintime'; then
    pass "Remote 'upstream' -> bit-team/backintime OK"
  else
    fail "Falta remote 'upstream' apontando para bit-team/backintime"
  fi
  if echo "$REMOTES" | grep -q 'origin.*BrunoAnalytics/backintime'; then
    pass "Remote 'origin' -> BrunoAnalytics/backintime OK"
  else
    warn "Não encontrei 'origin' -> BrunoAnalytics/backintime (verifique se está certo para seu fork)"
  fi
  if [ -z "$DIRTY" ]; then
    pass "Working tree limpo (sem alterações não commitadas)"
  else
    warn "Há alterações não commitadas (recomendado commitar antes de enviar):"
    echo "$DIRTY" | sed 's/^/  /'
  fi
else
  fail "Este diretório não parece ser um repositório git."
fi

section "2) Tamanho do repositório (meta: < 200 MB)"
SIZE_DIR=$(du -sh . | awk '{print $1}')
echo "Tamanho da pasta de trabalho: $SIZE_DIR"
SIZE_BYTES=$(du -sb . | awk '{print $1}')
if [ "$SIZE_BYTES" -lt $((200*1024*1024)) ]; then
  pass "Tamanho total < 200 MB"
else
  fail "Tamanho >= 200 MB (reduza arquivos não necessários)"
fi

section "3) Dockerfile – checks rápidos"
if [ -f "$DOCKERFILE" ]; then
  pass "Dockerfile encontrado"
else
  fail "Dockerfile não encontrado na raiz"
fi

if grep -Eiq '^\s*(cmd|entrypoint).*cron' "$DOCKERFILE"; then
  fail "Dockerfile inicia cron no CMD/ENTRYPOINT (não é permitido)"
else
  pass "Dockerfile não inicia cron (ok)"
fi

if grep -Eq 'pytest.*common/test' "$DOCKERFILE"; then
  pass "Dockerfile roda pytest nos testes comuns"
else
  warn "Não identifiquei 'pytest -q common/test' no Dockerfile; verifique o CMD"
fi

if grep -q '/app/None' "$DOCKERFILE"; then
  pass "Dockerfile cria dummy /app/None para testes SSHCopyID"
else
  warn "Dockerfile não cria /app/None; os testes podem falhar se esperarem esse arquivo"
fi

section "4) Build da imagem Docker"
if docker build -t "$IMAGE_NAME" .; then
  pass "Build da imagem '$IMAGE_NAME' OK"
else
  fail "Falha no docker build"
fi

section "5) Execução da suíte de testes dentro do container"
TEST_LOG="$(mktemp)"
if docker run --rm "$IMAGE_NAME" | tee "$TEST_LOG"; then
  pass "Container executado"
else
  fail "Falha ao executar container"
fi

PASSED=$(grep -Eo '[0-9]+ passed' "$TEST_LOG" | awk '{sum+=$1} END{print sum+0}')
FAILED=$(grep -Eo '[0-9]+ failed' "$TEST_LOG" | awk '{sum+=$1} END{print sum+0}')
SKIPPED=$(grep -Eo '[0-9]+ skipped' "$TEST_LOG" | awk '{sum+=$1} END{print sum+0}')

echo "Resumo testes: ${PASSED:-0} passed, ${FAILED:-0} failed, ${SKIPPED:-0} skipped"
if [ "${FAILED:-0}" -eq 0 ] && [ "${PASSED:-0}" -ge 400 ]; then
  pass "Critério de testes OK (>=400 passed e 0 failed)"
else
  fail "Critério de testes NÃO atingido"
fi

section "6) Metadados para a plataforma"
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
echo "Issue selecionado : $ISSUE_URL"
echo "Commit hash atual  : $COMMIT_HASH"
echo "Imagem Docker      : $IMAGE_NAME"

section "RESULTADO FINAL"
if [ "$FAIL" -eq 0 ]; then
  ok "Tudo pronto para SUBMIT do 1º issue ✅"
  exit 0
else
  err "Encontramos $FAIL problema(s). Corrija antes de enviar."
  exit 1
fi
	
