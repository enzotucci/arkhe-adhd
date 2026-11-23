-- arkhe

-- Command + shift + b para abrir gui


-- armazenador de dados pessoal para TDAH e para mim
-- memo: informação rápida, que quero lembrar. 
--ela deve ser armazenadar de forma simples e rapida informacoes
-- apos isso, devoc conseguir linkar ideias, como no obsidian

-- aplicativo funciona por sessao
-- uma sessao eh um arquivo .md, com TÍTULO e CONTEXTO (do que é a sessao)
-- ele roda a funcao criar sessao com nome e insere o nome como #titulo: e ocntexto como #contexto
-- apos, abre em loop a funcao armazenar memo
-- armazena o memo numa estrutura table 
-- insere no arquivo APÓS fim da sessao

-- usar fn. antes de funcao
local fn = require("functions")
memos = {}

-- funcoes

-- local pasta, erro = fns.criar_pasta("memos")

-- sessoes ficam em arkhe_sessions, igual na gui: entra na pasta (cria se nao existir)
-- assim functions.lua continua usando so sessao .. ".md"
local ok, lfs = pcall(require, "lfs")

if not ok then
    print("Missing luafilesystem. Install it with: luarocks install luafilesystem")
    os.exit(1)
end

local pasta_projeto = arg[0]:match("^(.*)/[^/]*$") or "." -- pasta onde esta o arkhe.lua
local pasta_sessoes = "arkhe_sessions"

lfs.chdir(pasta_projeto)
lfs.mkdir(pasta_sessoes) -- se ja existir, so retorna erro e segue

local entrou, erro = lfs.chdir(pasta_sessoes)
if not entrou then
    print("Could not open folder " .. pasta_sessoes .. ":", erro)
    os.exit(1)
end

io.write("Session name:\n")
local sessao = io.read()

if not sessao or sessao == "" then
    print("Session name is empty.")
    os.exit(1)
end

local file = io.open(sessao .. ".md", "r")
if file then
    file:close()
    print("\nSaved memos:")
    for hora, valor in pairs(fn.ler_arquivo(sessao)) do
        print(hora, valor)
    end
    print()
else
    io.write("Session context:\n")
    local contexto = io.read()
    fn.criar_sessao(sessao, contexto)
end

fn.criar_memo()
fn.ler_memo()
fn.armazenar_memo(sessao)
