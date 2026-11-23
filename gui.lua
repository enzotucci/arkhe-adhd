-- gui do arkhe, feita com LÖVE (https://love2d.org)
-- rodar na pasta do projeto com: love .
-- o LÖVE chama sozinho as funcoes love.load, love.draw, love.keypressed etc
-- a logica dos memos continua em functions.lua; aqui fica so a tela

-- usar fn. antes de funcao
local fn = require("functions")
local utf8 = require("utf8")

memos = {} -- global, functions.lua usa ela

-- estado da tela
-- "sessao": pede o nome | "contexto": pede ou confirma o contexto | "memos": tela principal
local tela = "sessao"
local sessao = nil
local sessao_nova = false
local entrada = ""       -- texto sendo digitado
local lista = {}         -- memos mostrados: { {hora = , valor = , salvo = true/false}, ... }
local selecionado = nil  -- indice do memo selecionado em lista
local rolagem = 0        -- quantos pixels a lista desceu
local pasta_sessoes = "arkhe_sessions"
-- pasta do projeto, usada so pelo app compilado (arkhe.app); mude aqui se mover o projeto
local pasta_projeto = "/Users/enzotucci/Desktop/codigo/arkhe"
local sessoes = {}       -- nomes das sessoes .md encontradas em pasta_sessoes
local mostrar_sessoes = false

-- aparencia (edite a vontade)
local cores = {
    fundo    = {0.12, 0.12, 0.14},
    texto    = {0.92, 0.92, 0.92},
    apagado  = {0.55, 0.55, 0.60},
    caixa    = {0.20, 0.20, 0.24},
    destaque = {0.25, 0.45, 0.85},
}
local margem = 16
local altura_linha = 24
local altura_caixa = 36
local espaco_caixa = 20 -- espaco entre a pergunta e a caixa de texto
local topo_caixa = margem + altura_linha * 2 + espaco_caixa
local fonte

-- funcoes auxiliares

local function sessao_existe(nome)
    local file = io.open(nome .. ".md", "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- junta os memos do arquivo com os da memoria, ordenados pela hora
local function atualizar_lista()
    lista = {}

    for hora, valor in pairs(fn.ler_arquivo(sessao)) do
        table.insert(lista, {hora = hora, valor = valor, salvo = true})
    end
    for hora, valor in pairs(memos) do
        table.insert(lista, {hora = hora, valor = valor, salvo = false})
    end

    table.sort(lista, function(a, b) return a.hora < b.hora end)
    selecionado = nil
end

-- grava no arquivo os memos que so estao na memoria
local function salvar()
    if tela ~= "memos" or next(memos) == nil then
        return
    end

    fn.armazenar_memo(sessao)
    memos = {} -- ja estao no arquivo; limpa para nao gravar duas vezes
    atualizar_lista()
end

local function apagar_selecionado()
    local memo = lista[selecionado]
    if not memo then
        return
    end

    fn.apagar_memo(sessao, memo.hora)
    atualizar_lista()
end

-- chamada quando aperta Enter
local function confirmar_entrada()
    local texto = entrada
    entrada = ""

    if texto == "" then
        return
    end

    if tela == "sessao" then
        sessao = texto
        sessao_nova = not sessao_existe(sessao)
        tela = "contexto"

        -- sessao existente: a caixa ja vem com o contexto atual, para confirmar ou editar
        if not sessao_nova then
            entrada = fn.ler_contexto(sessao) or ""
        end
    elseif tela == "contexto" then
        if sessao_nova then
            fn.criar_sessao(sessao, texto)
        elseif texto ~= fn.ler_contexto(sessao) then
            fn.mudar_contexto(sessao, texto)
        end
        tela = "memos"
        atualizar_lista()
    elseif tela == "memos" then
        fn.adicionar_memo(texto)
        atualizar_lista()
    end
end

-- procura os .md de pasta_sessoes e guarda os nomes sem a extensao
local function listar_sessoes()
    sessoes = {}
    local arquivos = {}

    if love.filesystem.isFused() then
        -- app compilado: love.filesystem nao enxerga a pasta do projeto, entao lista com ls
        local ls = io.popen('ls "' .. pasta_projeto .. "/" .. pasta_sessoes .. '"')
        for arquivo in ls:lines() do
            table.insert(arquivos, arquivo)
        end
        ls:close()
    else
        arquivos = love.filesystem.getDirectoryItems(pasta_sessoes)
    end

    for _, arquivo in ipairs(arquivos) do
        local nome = arquivo:match("^(.+)%.md$")
        if nome then
            table.insert(sessoes, nome)
        end
    end

    table.sort(sessoes)
end

-- botao "Open session": mostra ou esconde a lista de sessoes
local function alternar_sessoes()
    mostrar_sessoes = not mostrar_sessoes
    if mostrar_sessoes then
        listar_sessoes()
    end
end

-- abrir pela lista faz o mesmo que digitar o nome e apertar Enter
local function abrir_sessao(nome)
    entrada = nome
    mostrar_sessoes = false
    confirmar_entrada()
end

-- posicoes calculadas a partir do tamanho da janela, para funcionar ao redimensionar

-- lista fica embaixo da caixa de texto e ocupa o resto da janela
local function area_lista()
    local largura, altura = love.graphics.getDimensions()
    local y = topo_caixa + altura_caixa + margem
    return margem, y, largura - margem * 2, altura - y - margem
end

-- botoes ficam ao lado da caixa de texto
local function botoes()
    local largura = love.graphics.getWidth()
    local y = topo_caixa
    local w = 90

    if tela == "sessao" then
        local w_abrir = 120
        return {
            {texto = "Open session", x = largura - margem - w_abrir, y = y, w = w_abrir, h = altura_caixa, acao = alternar_sessoes},
        }
    end

    -- TODO: adicionar mais botoes aqui (ex: buscar, trocar de sessao)
    return {
        {texto = "Save", x = largura - margem - w * 2 - 8, y = y, w = w, h = altura_caixa, acao = salvar},
        {texto = "Delete", x = largura - margem - w,         y = y, w = w, h = altura_caixa, acao = apagar_selecionado},
    }
end

local function dentro(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

-- callbacks do LÖVE

function love.load()
    -- garante que os .md fiquem na pasta do projeto, mesmo abrindo o LÖVE de outro lugar
    pcall(function()
        local ffi = require("ffi")
        ffi.cdef("int chdir(const char *path); int mkdir(const char *path, int mode);")

        -- rodando com "love ." usa a pasta de onde abriu; o app compilado usa pasta_projeto
        if love.filesystem.isFused() then
            ffi.C.chdir(pasta_projeto)
        else
            ffi.C.chdir(love.filesystem.getSource())
        end

        -- sessoes ficam em arkhe_sessions: entra na pasta (cria se nao existir)
        -- assim functions.lua continua usando so sessao .. ".md"
        ffi.C.mkdir(pasta_sessoes, 493) -- 493 = 0755, permissao padrao de pasta
        ffi.C.chdir(pasta_sessoes)
    end)

    fonte = love.graphics.newFont(16)
    love.graphics.setFont(fonte)
    love.keyboard.setKeyRepeat(true) -- segurar backspace apaga varias letras
end

function love.draw()
    local largura = love.graphics.getWidth()
    love.graphics.clear(cores.fundo)

    -- titulo
    love.graphics.setColor(cores.texto)
    if sessao and tela == "memos" then
        love.graphics.print("arkhe-adhd  -  " .. sessao, margem, margem)
    else
        love.graphics.print("arkhe-adhd", margem, margem)
    end

    -- texto de ajuda da tela atual
    local dica
    if tela == "sessao" then
        dica = "Session name (Enter to open or create):"
    elseif tela == "contexto" and sessao_nova then
        dica = "New session. Session context:"
    elseif tela == "contexto" then
        dica = "Session context (Enter to confirm, or edit):"
    else
        dica = "New memo (Enter to add, * = unsaved):"
    end
    love.graphics.setColor(cores.apagado)
    love.graphics.print(dica, margem, margem + altura_linha)

    -- lista de memos
    if tela == "memos" then
        local x, y, w, h = area_lista()
        love.graphics.setScissor(x, y, w, h)

        for i, memo in ipairs(lista) do
            local ly = y + (i - 1) * altura_linha - rolagem

            if i == selecionado then
                love.graphics.setColor(cores.destaque)
                love.graphics.rectangle("fill", x, ly, w, altura_linha)
            end

            local marca = memo.salvo and "  " or "* "
            love.graphics.setColor(cores.apagado)
            love.graphics.print(marca .. memo.hora, x + 4, ly + 2)
            love.graphics.setColor(cores.texto)
            love.graphics.print(memo.valor, x + 200, ly + 2)
        end

        love.graphics.setScissor()
    end

    -- lista de sessoes (depois de clicar em "Open session")
    if tela == "sessao" and mostrar_sessoes then
        local x, y, w, h = area_lista()
        love.graphics.setScissor(x, y, w, h)

        if #sessoes == 0 then
            love.graphics.setColor(cores.apagado)
            love.graphics.print("No sessions in " .. pasta_sessoes, x + 4, y + 2)
        end

        for i, nome in ipairs(sessoes) do
            love.graphics.setColor(cores.texto)
            love.graphics.print(nome, x + 4, y + (i - 1) * altura_linha + 2)
        end

        love.graphics.setScissor()
    end

    -- caixa de texto
    local caixa_w = largura - margem * 2
    if tela ~= "contexto" then
        caixa_w = botoes()[1].x - margem - 8
    end
    local caixa_y = topo_caixa
    love.graphics.setColor(cores.caixa)
    love.graphics.rectangle("fill", margem, caixa_y, caixa_w, altura_caixa, 4)
    love.graphics.setColor(cores.texto)
    local cursor = (love.timer.getTime() % 1 < 0.5) and "|" or ""
    love.graphics.print(entrada .. cursor, margem + 8, caixa_y + (altura_caixa - fonte:getHeight()) / 2)

    -- botoes
    if tela ~= "contexto" then
        for _, b in ipairs(botoes()) do
            love.graphics.setColor(cores.caixa)
            love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 4)
            love.graphics.setColor(cores.texto)
            love.graphics.printf(b.texto, b.x, b.y + (b.h - fonte:getHeight()) / 2, b.w, "center")
        end
    end
end

-- letras digitadas (ja vem com acento certo)
function love.textinput(t)
    entrada = entrada .. t
end

function love.keypressed(tecla)
    local ctrl = love.keyboard.isDown("lctrl", "rctrl", "lgui", "rgui") -- gui = tecla cmd no mac

    if tecla == "return" or tecla == "kpenter" then
        confirmar_entrada()
    elseif tecla == "backspace" then
        -- apaga a ultima letra respeitando acentos (utf8)
        local inicio = utf8.offset(entrada, -1)
        if inicio then
            entrada = entrada:sub(1, inicio - 1)
        end
    elseif ctrl and tecla == "s" then
        salvar()
    elseif tela == "memos" and tecla == "delete" then
        apagar_selecionado()
    elseif tela == "memos" and tecla == "up" then
        selecionado = math.max(1, (selecionado or 2) - 1)
    elseif tela == "memos" and tecla == "down" then
        selecionado = math.min(#lista, (selecionado or 0) + 1)
    elseif tecla == "escape" then
        selecionado = nil
    end
end

function love.mousepressed(mx, my, botao)
    if botao ~= 1 or tela == "contexto" then
        return
    end

    for _, b in ipairs(botoes()) do
        if dentro(mx, my, b.x, b.y, b.w, b.h) then
            b.acao()
            return
        end
    end

    -- clique em uma sessao da lista abre ela
    local x, y, w, h = area_lista()
    if tela == "sessao" then
        if mostrar_sessoes and dentro(mx, my, x, y, w, h) then
            local i = math.floor((my - y) / altura_linha) + 1
            if sessoes[i] then
                abrir_sessao(sessoes[i])
            end
        end
        return
    end

    -- clique em um memo da lista seleciona ele
    if dentro(mx, my, x, y, w, h) then
        local i = math.floor((my - y + rolagem) / altura_linha) + 1
        if lista[i] then
            selecionado = i
        end
    end
end

function love.wheelmoved(_, dy)
    local _, _, _, h = area_lista()
    local maximo = math.max(0, #lista * altura_linha - h)
    rolagem = math.min(maximo, math.max(0, rolagem - dy * altura_linha))
end

-- ao fechar a janela, grava o que faltou (igual ao fim da sessao no terminal)
function love.quit()
    salvar()
end
