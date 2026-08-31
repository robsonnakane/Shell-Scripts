set -euo pipefail
##O comando "set -euo" faz o script parar imediatamente caso qualquer comando dentro dele retorne um erro (exit code diferente de 0).(-e → para no erro) (-u → trata variáveis não definidas como erro) (-o pipefail → considera falha em pipe () se qualquer comando falhar

sudo rsync -avzrp --delete /home/robsonnakane/'Robson Nakane'/ robsonnakane@nixos:/mnt/sda1/
