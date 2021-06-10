-- Author: L
-- Date: 2021-02-18

local open = io.open

local _M = { VERSION = 0.1 }

function _M.read_file(file_path)
    local file, err = open(file_path, "rb")
    if not file then
        return false, "failed to open file: " .. file_path .. ", error info:" .. err
    end

    local data, err = file:read("*all")
    if err ~= nil then
        file:close()
        return false, "failed to read file: " .. file_path .. ", error info:" .. err
    end

    file:close()
    return data
end

function _M.write_file(file_path, data)
    local file, err = open(file_path, "w+")
    if not file then
        return false, "failed to open file: "
                .. file_path
                .. ", error info:"
                .. err
    end

    file:write(data)
    file:close()
    return true
end

function _M.is_file_exist(file_path)
    local file, err = open(file_path)
    if not file then
        return false, "failed to open file: "
                .. file_path
                .. ", error info: "
                .. err
    end

    file:close()
    return true
end

return _M