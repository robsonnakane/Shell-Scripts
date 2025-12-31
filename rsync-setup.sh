#!/bin/bash

# =============================================================================
# Script: rsync-setup.sh
# Autor: Grok (xAI)
# Descrição: Configura rsync + SSH + firewall + verifica criptografia em qualquer distro Linux
# Uso: sudo ./rsync-setup.sh
# =============================================================================

set -euo pipefail

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1" >&2; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }

# Verifica se é root
if [[ $EUID -ne 0 ]]; then
   error "Este script precisa ser executado como root (use sudo)."
   exit 1
fi

# =============================================================================
# 1. DETECTAR DISTRIBUIÇÃO
# =============================================================================
detect_distro() {
    log "Detectando distribuição Linux..."

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="${ID}"
        DISTRO_VERSION="${VERSION_ID:-}"
    else
        error "Não foi possível detectar a distribuição (arquivo /etc/os-release ausente)."
        exit 1
    fi

    case "$DISTRO_ID" in
        ubuntu|debian|linuxmint|pop|zorin|kali)
            DISTRO_FAMILY="debian"
            PACKAGE_MANAGER="apt"
            INSTALL_CMD="apt install -y"
            UPDATE_CMD="apt update -y"
            FIREWALL_TOOL="ufw"
            ;;
        fedora|rhel|centos|almalinux|rocky|ol)
            DISTRO_FAMILY="redhat"
            PACKAGE_MANAGER="dnf"
            INSTALL_CMD="dnf install -y"
            UPDATE_CMD="dnf check-update || true"
            FIREWALL_TOOL="firewalld"
            ;;
        arch|manjaro|endeavouros|garuda)
            DISTRO_FAMILY="arch"
            PACKAGE_MANAGER="pacman"
            INSTALL_CMD="pacman -Syu --noconfirm"
            UPDATE_CMD="pacman -Syu --noconfirm"
            FIREWALL_TOOL="iptables"
            ;;
        opensuse|sles|gecko)
            DISTRO_FAMILY="suse"
            PACKAGE_MANAGER="zypper"
            INSTALL_CMD="zypper install -y --no-confirm"
            UPDATE_CMD="zypper refresh"
            FIREWALL_TOOL="SuSEfirewall2"
            ;;
        *)
            error "Distribuição não suportada: $DISTRO_ID"
            exit 1
            ;;
    esac

    success "Distribuição detectada: $PRETTY_NAME ($DISTRO_FAMILY)"
}

# =============================================================================
# 2. INSTALAR RSYNC E OPENSSH-SERVER
# =============================================================================
install_rsync_ssh() {
    log "Atualizando repositórios..."
    $UPDATE_CMD >/dev/null 2>&1 || warn "Falha ao atualizar repositórios (continuando)."

    log "Instalando rsync e openssh-server..."
    case "$DISTRO_FAMILY" in
        debian)
            $INSTALL_CMD rsync openssh-server
            systemctl enable sshd --now
            systemctl start sshd --now
            ;;
        redhat)
            $INSTALL_CMD rsync openssh-server
            systemctl enable sshd --now
            systemctl start sshd --now
            ;;
        arch)
            $INSTALL_CMD rsync openssh-server
            systemctl enable sshd --now
            systemctl start sshd --now
            ;;
        suse)
            $INSTALL_CMD rsync openssh-server
            systemctl enable sshd --now
            systemctl start sshd --now
            ;;
    esac

    success "rsync e SSH instalados e habilitados."
}

# =============================================================================
# 3. LIBERAR PORTA 22 NO FIREWALL
# =============================================================================
open_ssh_port() {
    log "Liberando porta 22 (SSH) no firewall..."

    case "$FIREWALL_TOOL" in
        ufw)
            if ! ufw status | grep -q "22.*ALLOW"; then
                ufw allow 22/tcp
                ufw reload
                success "Porta 22 liberada no UFW."
            else
                success "Porta 22 já liberada no UFW."
            fi
            ;;
        firewalld)
            if ! firewall-cmd --list-services | grep -q "ssh"; then
                firewall-cmd --permanent --add-service=ssh
                firewall-cmd --reload
                success "Porta 22 (ssh) liberada no firewalld."
            else
                success "Serviço SSH já liberado no firewalld."
            fi
            ;;
        iptables)
            if ! iptables -L -n | grep -q "dpt:22"; then
                iptables -A INPUT -p tcp --dport 22 -j ACCEPT
                if command -v iptables-save >/dev/null; then
                    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
                fi
                success "Porta 22 liberada no iptables."
            else
                success "Porta 22 já liberada no iptables."
            fi
            ;;
        SuSEfirewall2)
            if ! grep -q "FW_SERVICES_ACCEPT_RELATED_EXT.*tcp.*22" /etc/sysconfig/SuSEfirewall2; then
                sed -i '/FW_SERVICES_ACCEPT_RELATED_EXT/c\FW_SERVICES_ACCEPT_RELATED_EXT="tcp/22"' /etc/sysconfig/SuSEfirewall2
                rcSuSEfirewall2 restart
                success "Porta 22 liberada no SuSEfirewall2."
            else
                success "Porta 22 já liberada no SuSEfirewall2."
            fi
            ;;
        *)
            warn "Firewall não gerenciado automaticamente ($FIREWALL_TOOL)."
            ;;
    esac
}

# =============================================================================
# 4. VERIFICAR CRIPTOGRAFIA NO DISCO (LUKS)
# =============================================================================
check_encryption() {
    log "Verificando criptografia no disco raiz..."

    ROOT_DEV=$(findmnt -n -o SOURCE /)
    ROOT_DEV=$(realpath "$ROOT_DEV" | sed 's/p[0-9]*$//')  # Remove partição

    if cryptsetup status "$ROOT_DEV" >/dev/null 2>&1 || \
       lsblk -f | grep -q "crypto_LUKS.*$ROOT_DEV"; then
        success "Disco raiz criptografado com LUKS."
    else
        warn "Disco raiz NÃO está criptografado com LUKS."
        echo -e "${YELLOW}DICA: Use 'cryptsetup luksFormat' para criptografar (requer reinstalação ou backup).${NC}"
    fi
}

# =============================================================================
# 5. TESTE FINAL DO RSYNC VIA SSH LOCAL
# =============================================================================
test_rsync_ssh() {
    log "Testando rsync via SSH local..."

    if rsync -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
             --dry-run /etc/hosts localhost:/tmp/.rsync_test 2>/dev/null; then
        success "rsync via SSH funcionando localmente."
    else
        error "Falha no teste rsync via SSH. Verifique chaves SSH ou rede."
    fi

    # Limpeza
    ssh localhost "rm -f /tmp/.rsync_test" 2>/dev/null || true
}

# =============================================================================
# EXECUÇÃO PRINCIPAL
# =============================================================================
main() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}   CONFIGURADOR UNIVERSAL DO RSYNC     ${NC}"
    echo -e "${BLUE}=======================================${NC}"

    detect_distro
    install_rsync_ssh
    open_ssh_port
    check_encryption
    test_rsync_ssh

    echo -e "\n${GREEN}Configuração concluída com sucesso!${NC}"
    echo -e "${GREEN}Você pode usar rsync via SSH agora.${NC}"
    echo -e "${YELLOW}Exemplo: rsync -avz /local/ user@host:/remoto/${NC}"
}

# Executa
main
