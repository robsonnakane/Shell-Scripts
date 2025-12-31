#!/bin/bash

# Script para configurar SSH passwordless do host local (origem) para um host remoto (destino)
# Uso: ./setup_ssh_passwordless.sh usuario@ip_destino
# Exemplo: ./setup_ssh_passwordless.sh root@192.168.1.100

if [ -z "$1" ]; then
  echo "Uso: $0 usuario@ip_ou_hostname_destino"
  echo "Exemplo: $0 root@192.168.1.50"
  exit 1
fi

REMOTE="$1"
KEY_PATH="$HOME/.ssh/id_ed25519"  # Usa ed25519 (moderno e seguro)

echo "=== Configurando SSH passwordless para $REMOTE ==="

# 1. Gera chave SSH se não existir (sem passphrase)
if [ ! -f "$KEY_PATH" ]; then
  echo "Gerando chave SSH ed25519 sem passphrase..."
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -q
else
  echo "Chave já existe em $KEY_PATH"
fi

# 2. Copia a chave pública para o remoto (aceita fingerprint automaticamente)
echo "Copiando chave pública para $REMOTE..."
ssh-copy-id -o StrictHostKeyChecking=accept-new -i "${KEY_PATH}.pub" "$REMOTE"

# Se ssh-copy-id não estiver disponível, fallback manual:
# ssh -o StrictHostKeyChecking=accept-new "$REMOTE" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
# cat "${KEY_PATH}.pub" | ssh -o StrictHostKeyChecking=accept-new "$REMOTE" "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# 3. Testa a conexão passwordless
echo "Testando conexão sem senha..."
ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$REMOTE" "echo 'Sucesso! Conexão passwordless funcionando em:' && hostname && date"

if [ $? -eq 0 ]; then
  echo "Configuração concluída com sucesso!"
  echo "Agora você pode acessar $REMOTE sem senha: ssh $REMOTE"
else
  echo "Falha na conexão. Verifique usuário, senha inicial, firewall ou permissões."
fi
