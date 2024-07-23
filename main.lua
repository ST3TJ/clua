local code = [[
int a = 1 + 2
float b = 0.5 + a
function add(x, y) return x + y end
int c = add(a, b)
]]

local syntax = {
    int = 'variable',
    float = 'variable',
    auto = 'variable',
    ['function'] = 'function'
}

local handlers = {
    variable = '(%w+)%s+(%w+)%s*=%s*(.+)',
    ['function'] = 'function%s+(%w+)%s*%(([%w%s,]*)%)%s*(.+)%s*end'
}

local memory = {}
local functions = {}

---comment
---@param expr string
---@return string
local function replace_variables(expr)
    for var, data in pairs(memory) do
        expr = expr:gsub("%f[%w]" .. var .. "%f[%W]", tostring(data.value))
    end
    return expr
end

---@param expr string
---@return any|nil
local function evaluate_expression(expr)
    expr = replace_variables(expr)
    local func, err = load("return " .. expr)
    if not func then
        print("Compilation error: " .. err)
        return nil
    end

    local success, result = pcall(func)
    if not success then
        print("Execution error: " .. result)
        return nil
    end

    return result
end

---@param name string
---@param args string
---@return any|nil
local function call_function(name, args)
    local func = functions[name]
    if not func then
        print("Function not found: " .. name)
        return nil
    end

    local arg_values = {}
    for arg in args:gmatch("([^,]+)") do
        arg = evaluate_expression(arg)
        table.insert(arg_values, arg)
    end

    if #arg_values ~= #func.args then
        print("Argument mismatch for function " .. name)
        return nil
    end

    local func_env = {}
    for i, arg_name in ipairs(func.args) do
        func_env[arg_name] = arg_values[i]
    end

    local func_body = func.body
    local func_with_env = function()
        local fn = load(func_body)
        setfenv(fn, func_env)
        local success, result = pcall(fn)
        if not success then
            print("Function execution error: " .. result)
            return nil
        end
        return result
    end

    return func_with_env()
end

local function interpreter()
    for line in code:gmatch("[^\r\n]+") do
        for keyword, token_type in pairs(syntax) do
            if line:match("^" .. keyword) then
                local pattern = handlers[token_type]

                if token_type == 'variable' then
                    local variable_type, variable_name, variable_value = line:match(pattern)

                    if not (variable_type and variable_name and variable_value) then
                        print("String does not match the pattern")
                        goto continue
                    end

                    local calculated_variable_value = nil

                    if variable_value:match("(%w+)%((.*)%)") then
                        local func_name, func_args = variable_value:match("(%w+)%((.*)%)")
                        calculated_variable_value = call_function(func_name, func_args)
                    else
                        calculated_variable_value = evaluate_expression(variable_value)
                    end

                    memory[variable_name] = {
                        type = variable_type,
                        value = calculated_variable_value
                    }

                    print("Variable type: " .. variable_type)
                    print("Variable name: " .. variable_name)
                    print("Variable value: " .. tostring(variable_value))
                    print("Calculated variable value: " .. tostring(calculated_variable_value))
                elseif token_type == 'function' then
                    local func_name, func_args, func_body = line:match(pattern)

                    if not func_name or not func_args or not func_body then
                        print("String does not match the pattern")
                        goto continue
                    end

                    local arg_list = {}
                    for arg in func_args:gmatch("(%w+)") do
                        table.insert(arg_list, arg)
                    end

                    functions[func_name] = {
                        args = arg_list,
                        body = func_body
                    }

                    print("Function defined: " .. func_name)
                    print("Arguments: " .. table.concat(arg_list, ", "))
                end
                print('\n')
            end
        end

        ::continue::
    end
end

interpreter()