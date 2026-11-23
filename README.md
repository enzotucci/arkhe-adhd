# arkhe-adhd

Armazenador pessoal de notas rápidas (memos), pensado para TDAH: anotar rápido, sem fricção, e depois conseguir ligar ideias, como no Obsidian.

O app funciona por **sessão**. Cada sessão é um arquivo `.md`, guardado na pasta `arkhe_sessions` (criada ao iniciar, tanto pela GUI quanto pelo terminal), com título, contexto e os memos com data e hora:

```
#estudos
#   coisas de lua
2026-10-27 20:04:25 - um memo
2026-10-27 20:04:26 - outro memo
```

## Como rodar

### Interface gráfica (LÖVE)

Precisa do [LÖVE](https://love2d.org) 11.5. Na pasta do projeto:

```bash
love .
```

No macOS, se o comando `love` não estiver no PATH:

```bash
/Applications/love.app/Contents/MacOS/love .
```

- Na tela inicial, digite o nome de uma sessão ou clique em **Open session** para escolher uma das existentes
- **Enter** adiciona o memo
- **↑ / ↓** ou clique selecionam um memo
- **Delete** (tecla ou botão) remove o memo selecionado, inclusive do arquivo
- **Ctrl+S / Cmd+S** ou o botão **Save** gravam os memos novos (também grava ao fechar)

### App de macOS

Para gerar um `arkhe-adhd.app` que abre com dois cliques (precisa do LÖVE em `/Applications`):

```bash
./build_mac.sh
```

O app fica em `build/arkhe-adhd.app`. Antes, troque `pasta_projeto` no começo do `gui.lua` pelo caminho da pasta do projeto na sua máquina: é lá que o app compilado guarda as sessões. Se o projeto estiver na Mesa (Desktop) ou em Documentos, o macOS pede permissão de acesso na primeira vez.

### Terminal

Precisa de Lua 5.3 e da [LuaFileSystem](https://lunarmodules.github.io/luafilesystem/) (para criar e entrar na pasta `arkhe_sessions`):

```bash
luarocks install luafilesystem
lua arkhe.lua
```

## Estrutura

| Arquivo | O que faz |
| --- | --- |
| `functions.lua` | lógica dos memos e das sessões (usada pelas duas versões) |
| `arkhe.lua` | versão de terminal |
| `main.lua` | ponto de entrada do LÖVE (só carrega `gui.lua`) |
| `gui.lua` | interface gráfica |
| `conf.lua` | configuração da janela do LÖVE |
| `build_mac.sh` | gera o app de macOS em `build/` |

O LÖVE roda com LuaJIT (compatível com Lua 5.1), e o terminal com Lua 5.3. Por isso `functions.lua` deve usar só o que existe nas duas versões: nada de `//`, operadores de bits (`&`, `|`, `~`) ou `utf8` dentro dele.

## Licença

[MIT](LICENSE)
