#!/bin/bash

# Script para configurar SSH para GitHub de forma semi-automática
# Uso: ./setup_github_ssh.sh seuemail@exemplo.com

if [ -z "$1" ]; then
  echo "Uso: $0 seuemail@exemplo.com"
  exit 1
fi

EMAIL="$1"
KEY_PATH="$HOME/.ssh/id_ed25519"

echo "=== Configurando chave SSH para GitHub ==="

# 1. Gera a chave se não existir
if [ ! -f "$KEY_PATH" ]; then
  echo "Gerando nova chave SSH (ed25519)..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
else
  echo "Chave já existe em $KEY_PATH"
fi

# 2. Inicia o ssh-agent e adiciona a chave
echo "Iniciando ssh-agent e adicionando chave..."
eval "$(ssh-agent -s)"
ssh-add "$KEY_PATH"

# 3. Exibe a chave pública para copiar
echo ""
echo "=== CHAVE PÚBLICA (copie tudo abaixo) ==="
cat "${KEY_PATH}.pub"
echo ""
echo "=== FIM DA CHAVE ==="
echo ""
echo "Agora vá para o GitHub:"
echo "1. Acesse: https://github.com/settings/keys"
echo "2. Clique em 'New SSH key'"
echo "3. Título: algo como 'Meu PC - $(hostname)'"
echo "4. Cole a chave pública no campo 'Key'"
echo "5. Clique em 'Add SSH key'"
echo ""

# 4. Testa a conexão (após adicionar no GitHub)
read -p "Você já adicionou a chave no GitHub? (s/n): " resposta
if [[ "$resposta" =~ ^[Ss]$ ]]; then
  echo "Testando conexão SSH..."
  ssh -T git@github.com
  if [ $? -eq 1 ]; then  # Código 1 significa autenticação OK
    echo "Sucesso! Conexão SSH com GitHub configurada."
  else
    echo "Falha na conexão. Verifique a chave no GitHub."
  fi
else
  echo "Adicione a chave no GitHub e rode novamente o teste: ssh -T git@github.com"
fi

echo "Configuração concluída! Agora você pode usar git com SSH (ex: git clone git@github.com:usuario/repo.git)"
