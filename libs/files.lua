local files = {}; do
    ---@param path string
    ---@param text string
    ---@return boolean result
    files.save = function(path, text)
        local handle = io.open(path, 'w');
        if not handle then
            return false;
        end;

        if not handle:write(text) then
            return false;
        end;

        return true;
    end;

    ---@param path string
    ---@return string?
    files.read = function(path)
        local handle = io.open(path, 'r');
        if not handle then
            return;
        end;

        return handle:read('*a');
    end;
end;

return files;
