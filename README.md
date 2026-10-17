# canivt

Gerenciador de arquivos e editor de texto para o terminal Linux, com barra de favoritos e acesso a servidores Samba (SMB).

É um único arquivo Python, sem dependências além da biblioteca padrão, e abre instantaneamente.

## Instalação

```sh
git clone https://github.com/ezequieljc/canivt.git
./canivt/install.sh
```

Ou, sem clonar:

```sh
curl -fsSL https://raw.githubusercontent.com/ezequieljc/canivt/main/install.sh | bash
```

O instalador coloca o `canivt` em `~/.local/bin` (não precisa de root) e oferece instalar as dependências opcionais pelo gerenciador de pacotes da distro (apt, dnf, pacman ou zypper):

| Pacote | Para quê |
| --- | --- |
| `xclip` ou `wl-clipboard` | copiar texto do editor para outros programas |
| `gvfs-backends` + `gvfs-fuse` (`gvfs-smb` no Fedora/Arch) | acessar servidores Samba |

Opções: `--system` instala em `/usr/local/bin`, `--no-deps` pula as dependências e `--uninstall` remove.

Requer Python 3.9 ou mais novo. Os ícones usam uma [Nerd Font](https://www.nerdfonts.com); sem ela, rode `CANIVT_ASCII=1 canivt`.

## Uso

```sh
canivt                      # pasta atual
canivt ~/Documentos         # uma pasta
canivt notas.txt            # abre direto no editor
canivt smb://192.168.0.10/dados
```

### Navegação

| Tecla | Ação |
| --- | --- |
| `↑` `↓` | mover na lista |
| `→` / `Enter` | entrar na pasta ou abrir o arquivo |
| `←` / `Backspace` | voltar uma pasta |
| `1` a `9`, `0` | ir para um favorito ou servidor da barra lateral |
| `f` | favoritar ou desfavoritar a pasta |
| `/` | filtrar a lista |
| `.` | mostrar arquivos ocultos |
| `~` / `\` | ir para a home / para a raiz |
| `g` | ir para um caminho digitado |
| `n` / `N` | novo arquivo / nova pasta |
| `r` | renomear |
| `Del` | excluir (vai para a lixeira) |
| `c` / `x` / `v` | copiar / recortar / colar |
| `o` | abrir com o programa padrão do sistema |
| `b` | mostrar ou esconder a barra lateral |
| `q` | sair |

O caminho no topo e a barra lateral também respondem ao mouse.

### Editor

Arquivos de texto abrem no editor embutido. Os atalhos ficam sempre visíveis no rodapé:

| Tecla | Ação |
| --- | --- |
| `Ctrl+S` | salvar |
| `Ctrl+Q` / `Esc` | sair |
| `Ctrl+F` / `F3` | buscar / próximo resultado |
| `Ctrl+G` | ir para a linha |
| `Ctrl+Z` / `Ctrl+Y` | desfazer / refazer |
| `Ctrl+A` | selecionar tudo |
| `Shift+setas`, mouse | selecionar |
| `Ctrl+C` / `Ctrl+X` / `Ctrl+V` | copiar / recortar / colar |
| `Ctrl+D` | duplicar a linha |
| `Tab` / `Shift+Tab` | indentar / desindentar |

Todo texto selecionado vai automaticamente para a área de transferência do sistema. Sem seleção, `Ctrl+C` e `Ctrl+X` agem na linha inteira.

### Servidores Samba

Aperte `s` e informe o endereço, o usuário e a senha. Deixe o compartilhamento em branco para escolher numa lista. O servidor fica salvo na barra lateral e as pastas dele podem ser favoritadas como qualquer outra; se o servidor estiver desconectado, abrir o favorito reconecta.

`u` desconecta e `S` esquece um servidor salvo.

O acesso usa o gvfs, então os arquivos remotos se comportam como locais: dá para editar, copiar entre o computador e o servidor, renomear e excluir. Arquivos excluídos no servidor não vão para a lixeira.

## Arquivos de configuração

| Arquivo | Conteúdo |
| --- | --- |
| `~/.config/canivt/favoritos.json` | lista de favoritos |
| `~/.config/canivt/servidores.json` | servidores salvos, **com a senha em texto puro** (permissão 600) |

### Voltar para a última pasta ao sair

O canivt grava a última pasta visitada em `~/.cache/canivt/lastdir`. Com esta função no `~/.bashrc`, o terminal fica na pasta onde você saiu:

```sh
cv() { canivt "$@"; cd "$(cat ~/.cache/canivt/lastdir)"; }
```

## Licença

GPL-3.0-or-later. Veja [LICENSE](LICENSE).
