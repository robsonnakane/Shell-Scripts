#!/bin/bash

# --- EXPLICAÇÃO TÉCNICA (EDID & DRM) ---
# Em um TTY puro (fora do ambiente gráfico), o comando 'xrandr' não funciona.
# Para identificar as resoluções suportadas pelo monitor diretamente pelo kernel, 
# precisamos ler os arquivos de status do subsistema de vídeo DRM (Direct Rendering Manager).
# Este script escaneia as conexões ativas em /sys/class/drm/, extrai os modos válidos,
# seleciona a maior resolução disponível (ideal) e aplica via xrandr assim que o X11 iniciar.

echo "=========================================================="
echo "  OTIMIZADOR DE RESOLUÇÃO AUTOMÁTICO (EDID/DRM) para TTY  "
echo "=========================================================="
echo "Buscando monitores conectados e resoluções ideais..."

CONEXAO_ATIVA=""
RESOLUCAO_IDEAL=""

# 1. Escanear conectores de vídeo ativos no sistema (/sys/class/drm)
for dispositivo in /sys/class/drm/card*-*; do
    if [ -d "$dispositivo" ]; then
        status_file="$dispositivo/status"
        modes_file="$dispositivo/modes"
        
        if [ -f "$status_file" ] && [ "$(cat "$status_file")" = "connected" ]; then
            # Extrai o nome da interface (ex: VGA-1, HDMI-A-1) do caminho do diretório
            nome_interface=$(basename "$dispositivo" | sed 's/card[0-9]-//')
            
            # O primeiro modo listado no arquivo 'modes' costuma ser a resolução nativa/ideal (EDID)
            if [ -f "$modes_file" ] && [ -s "$modes_file" ]; then
                modo_nativo=$(head -n 1 "$modes_file")
                
                echo "-> Encontrado: Interface [$nome_interface] com Resolução Ideal [$modo_nativo]"
                CONEXAO_ATIVA="$nome_interface"
                RESOLUCAO_IDEAL="$modo_nativo"
                break # Interrompe no primeiro monitor principal ativo encontrado
            fi
        fi
    fi
done

# Caso o EDID falhe completamente e o arquivo 'modes' esteja vazio (comum em cabos VGA ruins)
if [ -z "$RESOLUCAO_IDEAL" ]; then
    echo "⚠️ Alerta: Não foi possível ler a resolução nativa do monitor via hardware (EDID)."
    echo "Aplicando uma resolução segura padrão para monitores antigos (1280x1024 a 60Hz)..."
    CONEXAO_ATIVA="VGA-1" # Fallback comum
    RESOLUCAO_IDEAL="1280x1024"
fi

# Tratamento de string: remover possíveis sufixos para o comando cvt
LARGURA=$(echo "$RESOLUCAO_IDEAL" | cut -d'x' -f1)
ALTURA=$(echo "$RESOLUCAO_IDEAL" | cut -d'x' -f2 | cut -d'@' -f1)

echo "-> Configurando sistema para usar: ${LARGURA}x${ALTURA} na saída $CONEXAO_ATIVA"

# 2. Gerar os parâmetros de sincronização de tela usando o comando cvt
PARAMETROS_CVT=$(cvt $LARGURA $ALTURA 60 | grep "Modeline" | sed 's/Modeline //')
NOME_MODO=$(echo "$PARAMETROS_CVT" | awk '{print $1}' | tr -d '"')

# 3. Criar a rotina de inicialização automática para o ambiente gráfico (X11/LXQt)
# Como o X11 precisa estar rodando para o xrandr funcionar, injetamos este script no Xprofile
ARQUIVO_XPROFILE="$HOME/.xprofile"

cat << EOF > "$ARQUIVO_XPROFILE"
#!/bin/sh
# Configuração de tela gerada automaticamente via TTY Script
xrandr --newmode $PARAMETROS_CVT 2>/dev/null
xrandr --addmode $CONEXAO_ATIVA "$NOME_MODO" 2>/dev/null
xrandr --output $CONEXAO_ATIVA --mode "$NOME_MODO"
EOF

chmod +x "$ARQUIVO_XPROFILE"

echo "=========================================================="
echo "✅ Script concluído com sucesso!"
echo "As configurações foram salvas em: $ARQUIVO_XPROFILE"
echo "Agora você já pode iniciar o ambiente gráfico (ou reiniciar o sistema)."
echo "Para iniciar a interface agora, digite: startx (ou reinicie o gerenciador de login)"
echo "=========================================================="
