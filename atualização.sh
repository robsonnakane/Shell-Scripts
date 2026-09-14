#!/bin/bash

###Fedora Silverblue###
###Atualização completa do sistema###

set -euo pipefail
##O comando "set -euo" faz o script parar imediatamente caso qualquer comando dentro dele retorne um erro (exit code diferente de 0).(-e → para no erro) (-u → trata variáveis não definidas como erro) (-o pipefail → considera falha em pipe () se qualquer comando falhar

##Execução do arquivo de atualização no terminal##
#/var/home/archlinux/Documentos/'Atualização Silverblue.sh'#

#Edição do arquivo no terminal#
#nano /var/home/archlinux/Documentos/'Atualização Silverblue.sh'#

fastfetch && \
##Cancela a atualização automática dos repositórios##
rpm-ostree cancel && \
echo "$?"
##Limpeza cache##
rpm-ostree cleanup -mrpb  && \
echo "$?"
rpm-ostree override reset --all && \
echo "$?"
##Atualizção dos repositórios##
rpm-ostree refresh-md && \
echo "$?"
##Pesquisar a versão disponível##
ostree remote refs fedora && \
echo "$?"
###Criação do toolbox para rkhunter
#toolbox enter
##sudo dnf install rkhunter chkrootkit##

##Atualização e verificação do rkhunter
toolbox run -c fedora-toolbox-44 sudo rkhunter --update --propupd && \
echo "$?"
fastfetch && \
toolbox run -c fedora-toolbox-44 sudo rkhunter --check --skip-keypress --report-warnings-only && \
echo "$?"
rpm-ostree status && \
echo "$?"
##Atualização do Flatpak##
flatpak update -y && \
echo "$?"
##Atualização dos pacotes instalados via distrobox##
distrobox enter archlinux -- sudo pacman -Syyuu --noconfirm && \
echo "$?"
##Backup aos servidores##
rsync -avzrp --delete -e "ssh -o ConnectTimeout=5" /home/robsonnakane/'Robson Nakane'/ robsonnakane@voidlinuxserver:/home/robsonnakane/lenovo/ || echo "Aviso: Servidor offline. Pulando este backup."
rsync -avzrp --delete -e "ssh -o ConnectTimeout=5" /home/robsonnakane/'Robson Nakane'/ robsonnakane@nixos:/mnt/sdb1/ || echo "Aviso: Servidor offline. Pulando este backup."
##Conferência dos pacotes##
rpm-ostree upgrade --preview && \
##Atualização do sistema##
rpm-ostree upgrade && \

#Tailscale##
#rpm-ostree install -y tailscale distrobox btop gnome-tweaks  && \

##Login Tailscale (pós instalação)##
#systemctl enable --now tailscaled && \ sudo tailscale up --ssh --accept-dns --force-reauth && \

##Instalação de programas no distrobox##
#distrobox create --name archlinux --image archlinux:latest && \ distrobox enter archlinux -- sudo pacman -S --noconfirm fastfetch && \ distrobox enter archlinux -- sudo pacman -S --noconfirm simple-scan && \ distrobox enter archlinux -- sudo pacman -S --noconfirm kdenlive && \ distrobox enter archlinux -- sudo pacman -S --noconfirm inkscape && \ distrobox enter archlinux -- sudo pacman -S --noconfirm thunderbird && \ distrobox enter archlinux -- sudo pacman -S --noconfirm audacious && \ distrobox enter archlinux -- sudo pacman -S --noconfirm gimp && \ distrobox enter archlinux -- sudo pacman -S --noconfirm vlc && \ distrobox enter archlinux -- sudo pacman -S --noconfirm transmission-gtk && \ distrobox enter archlinux -- sudo pacman -S --noconfirm rpi-imager && \ distrobox enter archlinux -- sudo pacman -S --noconfirm gwenview && \ distrobox enter archlinux -- sudo pacman -S --noconfirm kate && \ distrobox enter archlinux -- sudo pacman -S --noconfirm yt-dlp && \

##Exportação dos pacotes instalados no distrobox##
#distrobox enter archlinux -- distrobox-export --app simple-scan && \ distrobox enter archlinux -- distrobox-export --app kdenlive && \ distrobox enter archlinux -- distrobox-export --app inkscape && \ distrobox enter archlinux -- distrobox-export --app thunderbird && \ distrobox enter archlinux -- distrobox-export --app audacious && \ distrobox enter archlinux -- distrobox-export --app gimp && \ distrobox enter archlinux -- distrobox-export --app vlc && \ distrobox enter archlinux -- distrobox-export --app transmission-gtk && \ distrobox enter archlinux -- distrobox-export --app rpi-imager && \ distrobox enter archlinux -- distrobox-export --app gwenview && \ distrobox enter archlinux -- distrobox-export --app kate && \

##Atualização de versão##
#rpm-ostree rebase fedora:fedora/44/x86_64/silverblue && \

##Instalação dos programas Flatpak##
#flatpak install flathub com.spotify.Client -uy && \flatpak install flathub us.zoom.Zoom -uy && \ flatpak install flathub org.onlyoffice.desktopeditors -uy && \ flatpak install flathub com.adobe.Flash-Player-Projector -uy && \ flatpak install flathub com.github.IsmaelMartinez.teams_for_linux -uy && \ flatpak install flathub org.fedoraproject.MediaWriter -uy && \ flatpak install flathub org.kde.kget -uy && \ flatpak install flathub org.videolan.VLC -uy && \ flatpak install flathub net.mkiol.SpeechNote -uy && \ flatpak install flathub com.saivert.pwvucontrol -uy && \ flatpak install flathub io.github.dvlv.boxbuddyrs -uy && \ flatpak install flathub org.telegram.desktop -uy && \ flatpak install flathub com.obsproject.Studio -uy && \ flatpak install flathub org.audacityteam.Audacity -uy && \ flatpak install flathub com.github.tchx84.Flatseal -uy && \ flatpak install flathub app.zen_browser.zen -uy && \ flatpak install flathub com.google.ChromeDev -uy && \ flatpak install flathub com.mattjakeman.ExtensionManager -uy && \

##Baixar um vídeo em melhor qualidade:##
#distrobox enter archlinux -- yt-dlp URL
    ##Baixar só áudio (MP3):
#distrobox enter archlinux -- yt-dlp -x --audio-format mp3 URL

systemctl reboot -i
