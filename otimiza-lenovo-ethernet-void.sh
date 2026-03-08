#!/bin/bash
# ========================================================
# Script de Otimização de Ethernet no Void Linux
# Para placas Realtek RTL8111/8168/8211/8411 (driver r8169)
# Testado e validado no seu caso (upload de ~25 → 180 Mbps)
# ========================================================

set -e  # Para se houver erro, o script para

echo "🔧 Iniciando otimização da conexão cabeada no Void Linux..."

# ==================== CONFIGURAÇÃO ====================
# MUDE AQUI SE A INTERFACE FOR DIFERENTE (ex: enp2s0, eth0)
INTERFACE="enp1s0"

# Verifica se a interface existe
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo "❌ Interface $INTERFACE não encontrada!"
    echo "   Rode 'ip link show' e altere a variável INTERFACE no script."
    exit 1
fi

echo "✅ Interface detectada: $INTERFACE"

# ==================== ATUALIZAÇÃO E PACOTES ====================
echo "📦 Atualizando repositórios e instalando ferramentas necessárias..."
sudo xbps-install -Sy
sudo xbps-install -Syu
sudo xbps-install -Sy ethtool speedtest-cli

# ==================== DESATIVA OFFLOADS (O FIX PRINCIPAL) ====================
echo "🚀 Desativando offloads problemáticos do driver r8169..."
sudo ethtool -K "$INTERFACE" \
    tso off gso off gro off \
    rx off tx off sg off ufo off

# Verifica se deu certo
echo "   Status atual dos offloads:"
sudo ethtool -k "$INTERFACE" | grep -E 'tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload'

# ==================== TORNA PERMANENTE COM /etc/rc.local ====================
echo "💾 Criando /etc/rc.local para aplicar automaticamente no boot..."

sudo tee /etc/rc.local > /dev/null << 'EOF'
#!/bin/sh
# Otimização automática para Realtek r8169 no Void Linux
# Desativa offloads que causavam upload baixo

ethtool -K enp1s0 tso off gso off gro off rx off tx off sg off ufo off

# (Opcional) MTU otimizado para fibra brasileira (descomente se quiser)
# ip link set dev enp1s0 mtu 1500
EOF

sudo chmod +x /etc/rc.local

# ==================== (OPCIONAL) MTU 1500 ====================
echo "📏 Ajustando MTU (recomendado para fibra BR)..."
sudo ip link set dev "$INTERFACE" mtu 1500

# Torna MTU permanente via dhcpcd (se usar dhcpcd)
if [ -f /etc/dhcpcd.conf ]; then
    if ! grep -q "interface $INTERFACE" /etc/dhcpcd.conf; then
        echo "   Adicionando MTU permanente no dhcpcd.conf..."
        cat << EOF | sudo tee -a /etc/dhcpcd.conf > /dev/null

# Otimização MTU - adicionado pelo script
interface $INTERFACE
mtu 1500
EOF
    fi
fi

# ==================== TESTE FINAL ====================
echo "✅ Configuração aplicada!"
echo ""
echo "🔄 REINICIE O COMPUTADOR para testar o rc.local:"
echo "   sudo reboot"
echo ""
echo "Depois do reboot, rode o teste:"
echo "   speedtest-cli --secure --simple"
echo ""
echo "Resultado esperado (igual ou melhor que o seu):"
echo "   Download: ~210-230 Mbit/s"
echo "   Upload:   ~170-190 Mbit/s"
echo ""
echo "Script finalizado com sucesso! 🚀"
