local files = require 'libs.files'

local lexer = {
    token_types = {
        IDENTIFIER = "IDENTIFIER", -- Переменные и функции
        NUMBER = "NUMBER",         -- Числа
        OPERATOR = "OPERATOR",     -- Операторы (+, -, *, /)
        KEYWORD = "KEYWORD",       -- Ключевые слова (local, print)
        SYMBOL = "SYMBOL",         -- Специальные символы ((), =)
        EOF = "EOF"                -- Конец файла
    },
    keywords = {
        ["local"] = true,
        ["print"] = true
    }
}; do
    local tokens = {}

    function TOKEN(type, value)
        table.insert(tokens, { type = type, value = value })
    end

    function lexer:tokenize(code)
        local i = 1

        while i <= #code do
            local char = code:sub(i, i)

            if char:match("%s") then
                i = i + 1
            elseif char:match("%d") then
                local num = char
                i = i + 1
                while code:sub(i, i):match("%d") do
                    num = num .. code:sub(i, i)
                    i = i + 1
                end
                TOKEN(lexer.token_types.NUMBER, num)
            elseif char:match("%a") then
                local ident = char
                i = i + 1
                while code:sub(i, i):match("[%w_]") do
                    ident = ident .. code:sub(i, i)
                    i = i + 1
                end
                if lexer.keywords[ident] then
                    TOKEN(lexer.token_types.KEYWORD, ident)
                else
                    TOKEN(lexer.token_types.IDENTIFIER, ident)
                end
            elseif char == "+" or char == "-" or char == "*" or char == "/" then
                TOKEN(lexer.token_types.OPERATOR, char)
                i = i + 1
            elseif char == "(" or char == ")" or char == "=" then
                TOKEN(lexer.token_types.SYMBOL, char)
                i = i + 1
            else
                i = i + 1
            end
        end

        table.insert(tokens, { type = lexer.token_types.EOF })

        return tokens
    end
end

return lexer
