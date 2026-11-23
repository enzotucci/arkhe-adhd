local fns = {}

-- aplicativo funciona por sessao
-- uma sessao eh um arquivo .md, com TÍTULO e CONTEXTO (do que é a sessao)
-- ele roda a funcao criar sessao com nome e insere o nome como #titulo: e ocntexto como #contexto
-- apos, abre em loop a funcao armazenar memo
-- armazena o memo numa estrutura table 
-- insere no arquivo APÓS fim da sessao


-- cria sessao
function fns.criar_sessao(nome_sessao, contexto_da_sessao)
    local hora = os.date("%Y-%m-%d %H:%M:%S")
    local file, erro = io.open(nome_sessao .. ".md", "a")

    if not file then
        print("Could not open file:", erro)
        return
    end

    file:write("#", nome_sessao, "\n")
    file:write("#   ", contexto_da_sessao, "\n")
    file:close()

end

-- busca memo pela hora ou pelo texto
-- procura em memos, ou na tabela passada (ex: memos lidos do arquivo)
function fns.bsuca(alvo, tabela)
    tabela = tabela or memos

    for hora, valor in pairs(tabela) do
        if hora == alvo or valor == alvo then
            return hora, valor
        end
    end
end

-- le memo do usuario e o coloca na table memos
-- hora deve ser modo de buscar memo
function fns.criar_memo()
    for i = 1, 3 do
        io.write("What do you want to remember?\n")
        local valor = io.read()
        local hora = os.date("%Y-%m-%d %H:%M:%S")

        memos[hora] = valor
        print()
    end
end

-- e do arquivo?
-- le memos da memoria 
function fns.ler_memo()
    for hora, valor in pairs(memos) do
        print(hora, valor)
    end
end

-- armazena memo no arquivo
function fns.armazenar_memo(sessao)
    local file, erro = io.open(sessao .. ".md", "a")

    if not file then
        print("Could not open file:", erro)
        return
    end

    for hora, valor in pairs(memos) do
        file:write(hora, " - ", valor, "\n")
    end

    file:close()
end

-- le memos salvos no arquivo da sessao
-- deve rodar no inicio do programa
-- retorna uma table hora -> valor separada de memos, para armazenar_memo nao duplicar no arquivo
function fns.ler_arquivo(sessao)
    local salvos = {}
    local file = io.open(sessao .. ".md", "r")

    if not file then
        return salvos -- sessao ainda nao tem arquivo
    end

    for linha in file:lines() do
        local hora, valor = linha:match("^(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d) %- (.*)$")
        if hora then
            salvos[hora] = valor
        end
    end

    file:close()
    return salvos
end

-- le o contexto da sessao (linha "#   contexto" que criar_sessao escreve)
function fns.ler_contexto(sessao)
    local file = io.open(sessao .. ".md", "r")

    if not file then
        return nil
    end

    for linha in file:lines() do
        local contexto = linha:match("^#   (.*)$")
        if contexto then
            file:close()
            return contexto
        end
    end

    file:close()
    return nil
end

-- troca o contexto da sessao no arquivo, sem mexer nos memos
function fns.mudar_contexto(sessao, contexto)
    local file, erro = io.open(sessao .. ".md", "r")

    if not file then
        return false, erro
    end

    local linhas = {}
    local trocou = false

    for linha in file:lines() do
        if not trocou and linha:match("^#   ") then
            linha = "#   " .. contexto
            trocou = true
        end
        table.insert(linhas, linha)
    end
    file:close()

    file, erro = io.open(sessao .. ".md", "w")

    if not file then
        print("Could not open file:", erro)
        return false, erro
    end

    for _, linha in ipairs(linhas) do
        file:write(linha, "\n")
    end
    file:close()

    return true
end

-- adiciona memo na table memos sem perguntar nada (usado pela gui)
function fns.adicionar_memo(valor)
    local hora = os.date("%Y-%m-%d %H:%M:%S")
    memos[hora] = valor
    return hora
end

-- remove a linha do memo do arquivo da sessao, reescrevendo-o sem ela
function fns.remover_do_arquivo(sessao, hora, valor)
    local file, erro = io.open(sessao .. ".md", "r")

    if not file then
        return false, erro -- sessao ainda nao tem arquivo
    end

    local linhas = {}
    local alvo = hora .. " - " .. valor

    for linha in file:lines() do
        if linha ~= alvo then
            table.insert(linhas, linha)
        end
    end
    file:close()

    file, erro = io.open(sessao .. ".md", "w")

    if not file then
        print("Could not open file:", erro)
        return false, erro
    end

    for _, linha in ipairs(linhas) do
        file:write(linha, "\n")
    end
    file:close()

    return true
end

-- apaga memo pela hora ou pelo texto, da memoria e do arquivo, sem perguntar nada
-- retorna hora, valor do memo apagado, ou nil se nao achou
function fns.apagar_memo(sessao, alvo)
    -- procura primeiro nos memos em memoria, depois nos ja salvos no arquivo
    local hora, valor = fns.bsuca(alvo)
    if hora then
        memos[hora] = nil
    elseif sessao then
        hora, valor = fns.bsuca(alvo, fns.ler_arquivo(sessao))
    end

    if not hora then
        return nil
    end

    if sessao then
        fns.remover_do_arquivo(sessao, hora, valor)
    end

    return hora, valor
end

-- pergunta no terminal qual memo apagar
-- se receber a sessao, tambem remove do arquivo
function fns.remover_memo(sessao)
    print("Which memo do you want to delete? (time or text)\n")
    fns.ler_memo()
    if sessao then
        for hora, valor in pairs(fns.ler_arquivo(sessao)) do
            print(hora, valor)
        end
    end
    print("\ntype it: \n")
    local memo_a_apagar = io.read()

    local hora, valor = fns.apagar_memo(sessao, memo_a_apagar)

    if not hora then
        print("Memo not found.")
    end

    return hora, valor
end

return fns 