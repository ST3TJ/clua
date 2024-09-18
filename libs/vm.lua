local vm = {}; do
    local registers = { AX = 0, CX = 0, IX = 0 }
    local flags = { zf = 0 }
    local memory = {}
    local program = {}
    local ip = 1
    local stack = {}
    local native_functions = {
        ['0'] = print,
    }

    local function eval_expression(expr)
        expr = expr:gsub("(%u%u)", function(reg)
            return registers[reg] or error("Unknown register: " .. reg)
        end)

        local fn = load("return " .. expr)
        if fn then
            return fn()
        else
            error("Failed to evaluate expression: " .. expr)
        end
    end

    local function parse_memory_access(expr)
        local inner_expr = expr:match("%[(.-)%]")
        if inner_expr then
            return eval_expression(inner_expr)
        else
            error("Invalid memory access syntax: " .. expr)
        end
    end

    local function is_memory_access(val)
        return val:match("^%[.*%]$") ~= nil
    end

    local function call_native_function(alias, ...)
        local fn = native_functions[alias]
        if fn then
            return fn(...)
        else
            error("Native function '" .. alias .. "' not found")
        end
    end

    local instructions = {
        ["MOV"] = function(args)
            local reg, val = args[1], args[2]
            if is_memory_access(val) then
                local addr = parse_memory_access(val)
                registers[reg] = memory[addr] or 0
            elseif is_memory_access(reg) then
                local addr = parse_memory_access(reg)
                memory[addr] = registers[val] or tonumber(val)
            elseif registers[val] then
                registers[reg] = registers[val]
            else
                registers[reg] = tonumber(val)
            end
        end,

        ["ADD"] = function(args)
            local reg1, reg2 = args[1], args[2]
            if is_memory_access(reg2) then
                local addr = parse_memory_access(reg2)
                registers[reg1] = registers[reg1] + (memory[addr] or 0)
            else
                registers[reg1] = registers[reg1] + (registers[reg2] or tonumber(reg2))
            end
        end,

        ["SUB"] = function(args)
            local reg1, reg2 = args[1], args[2]
            if is_memory_access(reg2) then
                local addr = parse_memory_access(reg2)
                registers[reg1] = registers[reg1] - (memory[addr] or 0)
            else
                registers[reg1] = registers[reg1] - (registers[reg2] or tonumber(reg2))
            end
        end,

        ["CMP"] = function(args)
            local reg1, reg2 = args[1], args[2]
            local val1 = registers[reg1]
            local val2

            if is_memory_access(reg2) then
                local addr = parse_memory_access(reg2)
                val2 = memory[addr] or 0
            else
                val2 = registers[reg2] or tonumber(reg2)
            end

            if val1 == val2 then
                flags.zf = 1
            else
                flags.zf = 0
            end
        end,

        ["JZ"] = function(args)
            local addr = tonumber(args[1])
            if flags.zf == 1 then
                ip = addr
            end
        end,

        ["JNZ"] = function(args)
            local addr = tonumber(args[1])
            if flags.zf == 0 then
                ip = addr
            end
        end,

        ["JMP"] = function(args)
            local addr = tonumber(args[1])
            ip = addr
        end,

        ["PUSH"] = function(args)
            local reg = args[1]
            table.insert(stack, registers[reg])
        end,

        ["POP"] = function(args)
            local reg = args[1]
            if #stack == 0 then
                error("Stack is empty")
            end
            registers[reg] = table.remove(stack)
        end,

        ["CALL"] = function(args)
            local alias = args[1]
            local reg_args = { unpack(args, 2) }

            local real_args = {}
            for _, reg in ipairs(reg_args) do
                table.insert(real_args, registers[reg])
            end

            registers["AX"] = call_native_function(alias, unpack(real_args))
        end,

        ["TOS"] = function(args)
            local reg = args[1]
            if #stack == 0 then
                error("Stack is empty")
            end
            registers[reg] = #stack
        end
    }

    function vm.parse(code)
        local program = {}

        for line in code:gmatch("[^\r\n]+") do
            line = line:gsub(";.*$", "")
            line = line:match("^%s*(.-)%s*$")

            if line ~= "" then
                table.insert(program, line)
            end
        end

        return program
    end

    function vm.load(prog)
        if type(prog) == 'table' then
            program = prog
        elseif type(prog) == 'string' then
            program = vm.parse(prog)
        end
    end

    function vm.run()
        while ip <= #program do
            local instruction_line = program[ip]
            local parts = {}
            for word in instruction_line:gmatch("%S+") do
                table.insert(parts, string.upper(word))
            end

            local instruction = parts[1]
            local args = { unpack(parts, 2) }

            if instructions[instruction] then
                instructions[instruction](args)
            else
                error("Unknown instruction: " .. instruction)
            end

            ip = ip + 1
        end
    end

    function vm.state()
        return { registers, memory, stack, flags, ip }
    end
end

return vm
