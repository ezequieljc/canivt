#!/usr/bin/env bash
# Instalador do canivt.
#
#   ./install.sh               instala em ~/.local/bin (sem sudo)
#   ./install.sh --system      instala em /usr/local/bin (usa sudo)
#   ./install.sh --no-deps     não oferece instalar dependências opcionais
#   ./install.sh --uninstall   remove o canivt
#
# Também funciona direto da internet:
#   curl -fsSL https://raw.githubusercontent.com/ezequieljc/canivt/main/install.sh | bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ezequieljc/canivt/main"
PREFIX="$HOME/.local/bin"
SUDO=""
DEPS=1
UNINSTALL=0

for arg in "$@"; do
    case "$arg" in
        --system) PREFIX="/usr/local/bin" ;;
        --no-deps) DEPS=0 ;;
        --uninstall) UNINSTALL=1 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "opção desconhecida: $arg" >&2; exit 1 ;;
    esac
done

if [ -t 1 ]; then
    bold=$'\e[1m'; red=$'\e[31m'; green=$'\e[32m'; yellow=$'\e[33m'; reset=$'\e[0m'
else
    bold=""; red=""; green=""; yellow=""; reset=""
fi
info() { echo "${bold}::${reset} $*"; }
ok()   { echo "${green}ok${reset} $*"; }
warn() { echo "${yellow}aviso:${reset} $*"; }
die()  { echo "${red}erro:${reset} $*" >&2; exit 1; }

# Perguntas leem do terminal, para funcionar também com "curl | bash".
ask() {
    local answer=""
    { true < /dev/tty; } 2>/dev/null || return 1  # sem terminal: não instala nada
    read -r -p "$1 [S/n] " answer < /dev/tty || true
    [[ -z "$answer" || "$answer" =~ ^[sSyY] ]]
}

if [ "$PREFIX" = "/usr/local/bin" ] && [ ! -w "$PREFIX" ]; then
    SUDO="sudo"
fi

if [ "$UNINSTALL" = 1 ]; then
    for dir in "$HOME/.local/bin" "/usr/local/bin"; do
        if [ -f "$dir/canivt" ]; then
            if [ -w "$dir" ]; then rm -f "$dir/canivt"; else sudo rm -f "$dir/canivt"; fi
            ok "removido $dir/canivt"
        fi
    done
    echo "Favoritos e servidores salvos ficam em ~/.config/canivt (apague se quiser)."
    exit 0
fi

# Python 3.9+ com curses
command -v python3 >/dev/null || die "python3 não encontrado. Instale o Python 3.9 ou mais novo."
python3 - <<'EOF' || die "o canivt precisa do Python 3.9+ com o módulo curses."
import sys, curses
sys.exit(sys.version_info < (3, 9))
EOF

# Dependências opcionais: área de transferência e acesso SMB
pm=""
for candidate in apt-get dnf pacman zypper; do
    if command -v "$candidate" >/dev/null; then pm="$candidate"; break; fi
done

missing=()
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    command -v wl-copy >/dev/null || missing+=(clipboard-wayland)
else
    command -v xclip >/dev/null || command -v xsel >/dev/null || missing+=(clipboard-x11)
fi
has_gvfs() {
    local d
    for d in /usr/libexec /usr/lib/gvfs /usr/lib /usr/libexec/gvfs; do
        [ -e "$d/$1" ] && return 0
    done
    return 1
}
has_gvfs gvfsd-smb && has_gvfs gvfsd-fuse || missing+=(smb)

if [ "$DEPS" = 1 ] && [ ${#missing[@]} -gt 0 ]; then
    packages=()
    for m in "${missing[@]}"; do
        case "$pm:$m" in
            *:clipboard-wayland) packages+=(wl-clipboard) ;;
            *:clipboard-x11) packages+=(xclip) ;;
            apt-get:smb|zypper:smb) packages+=(gvfs-backends gvfs-fuse) ;;
            dnf:smb) packages+=(gvfs-smb gvfs-fuse) ;;
            pacman:smb) packages+=(gvfs-smb) ;;
        esac
    done
    if [ -z "$pm" ]; then
        warn "não reconheci o gerenciador de pacotes; instale manualmente: xclip (ou wl-clipboard) e gvfs com suporte a SMB e FUSE."
    else
        echo
        info "Dependências opcionais que faltam: ${packages[*]}"
        echo "   xclip / wl-clipboard: copiar texto do editor para outros programas"
        echo "   gvfs: acessar servidores Samba (SMB)"
        if ask "Instalar agora com $pm (pede a senha do sudo)?"; then
            case "$pm" in
                apt-get) sudo apt-get install -y "${packages[@]}" ;;
                dnf) sudo dnf install -y "${packages[@]}" ;;
                pacman) sudo pacman -S --needed --noconfirm "${packages[@]}" ;;
                zypper) sudo zypper install -y "${packages[@]}" ;;
            esac
            if [[ " ${missing[*]} " == *" smb "* ]]; then
                warn "saia da sessão e entre de novo para o gvfs reconhecer o suporte a SMB."
            fi
        else
            warn "pulando dependências; o resto do canivt funciona normalmente."
        fi
    fi
fi

# Copia o programa (do clone local ou baixando do GitHub)
script="${BASH_SOURCE[0]:-}"
tmp=""
if [ -n "$script" ] && [ -f "$(dirname "$script")/canivt" ]; then
    src="$(dirname "$script")/canivt"
else
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    info "baixando o canivt..."
    if command -v curl >/dev/null; then
        curl -fsSL "$REPO_RAW/canivt" -o "$tmp" || die "não consegui baixar $REPO_RAW/canivt"
    elif command -v wget >/dev/null; then
        wget -qO "$tmp" "$REPO_RAW/canivt" || die "não consegui baixar $REPO_RAW/canivt"
    else
        die "preciso do curl ou do wget para baixar o canivt."
    fi
    src="$tmp"
fi

$SUDO mkdir -p "$PREFIX"
$SUDO install -m 755 "$src" "$PREFIX/canivt"
ok "canivt $("$PREFIX/canivt" --version | cut -d' ' -f2) instalado em $PREFIX/canivt"

# Garante que o diretório está no PATH
case ":$PATH:" in
    *":$PREFIX:"*) ;;
    *)
        line="export PATH=\"$PREFIX:\$PATH\""
        for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
            if [ -f "$rc" ] && ! grep -qF "$line" "$rc"; then
                printf '\n# canivt\n%s\n' "$line" >> "$rc"
                ok "adicionado $PREFIX ao PATH em $rc"
            fi
        done
        warn "abra um novo terminal (ou rode: $line) antes de usar."
        ;;
esac

if ! fc-list 2>/dev/null | grep -i "nerd" >/dev/null; then
    echo
    warn "nenhuma Nerd Font encontrada. Os ícones podem aparecer como quadrados;"
    echo "   instale uma de https://www.nerdfonts.com ou use: CANIVT_ASCII=1 canivt"
fi

echo
echo "Pronto! Rode ${bold}canivt${reset} para começar."
