# syntax=docker/dockerfile:1
FROM python:3.11-slim

WORKDIR /app

# 1) Deps base
RUN apt-get update && apt-get install -y --no-install-recommends \
  rsync git cron udev openssh-client python3-dbus jq \
 && rm -rf /var/lib/apt/lists/*


# 2) dbus: instala libs p/ compilar e força instalar via pip (mais confiável no slim)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libdbus-1-dev libglib2.0-dev gcc pkg-config \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir dbus-python

# 3) Test libs Python
RUN pip install --no-cache-dir -U pip pytest pyfakefs

# 4) Código
COPY . .

# (4.1) Entry points no CWD como arquivos (não symlinks)
RUN cp -f common/backintime ./backintime \
 && cp -f common/backintime.py ./backintime.py \
 && chmod +x ./backintime \
 && chmod +x common/backintime || true    # leave common/backintime executable for tests

 # (4.2) Dummy pubkey para testes do SSHCopyID (o teste usa o string "None" como caminho)
RUN printf 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDtest test@container\n' > /app/None \
 && printf 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDtest test@container\n' > /app/common/None


# 5) PYTHONPATH para imports relativos (inclui common primeiro)
ENV PYTHONPATH=/app/common:/app
# Garante que /app tenha prioridade na busca de executáveis
ENV PATH="/app:${PATH}"


# (5.1) Rodar como usuário sem privilégios p/ comportar testes de permissão
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser


# 6) Rode a suíte COMMON primeiro (baseline), depois a QT (vamos habilitar depois)
CMD bash -lc '\
  echo "== Running common tests ==" && \
  cd common && PYTHONPATH=/app/common pytest -q test \
'
