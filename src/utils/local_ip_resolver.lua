--
--- 解析本地/etc/hosts: ip和hosts 
-- 来自:https://github.com/ysugimoto/lua-local-resolver/blob/master/local-resolver.lua

require("string")
require("io")
require("table")

-- Check file existence
-- Try to open file with read mode and close immediately
-- If succeed, returns true, otherwise returns false
local function file_exists(filename)
    local fp = io.open(filename, "r")
    if fp then
        fp:close()
        return true
    end
    return false
end

-- Clean up line string
--
-- 1. Remove comment characters which point of "#" is found
-- 2. Trim white space
local function cleanup_line(line)
    -- Trim comment
    local index = line:find("%#")
    if index then
        line = line:sub(1, index)
    end
    -- Trim white space
    line = line:gsub("^%s*(.-)%s*$", "%1")
    return line
end

-- Validate ip address is expected IPV4 or IPV6 format
local function validate_ip(ip)
    if not ip then
        return false
    end

    -- https://stackoverflow.com/questions/10975935/lua-function-check-if-ipv4-or-ipv6-or-string
    local chunks = { ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$") }
    if #chunks == 4 then
        for _, v in pairs(chunks) do
            if tonumber(v) > 255 then
                return false
            end
        end
        return 1 -- IPv4
    end

    local addr = ip:match("^([a-fA-F0-9:]+)$")
    if addr and #addr > 1 then
        local chunk_count = 0
        local double_colon = false
        for chunk, colons in addr:gmatch("({^:]*)(:*)") do
            if chunk_count > (double_colon and 7 or 8) then
                return false
            end
            if #chunk > 0 and tonumber(chunk, 10) > 65535 then
                return false
            end
            if #colons > 0 then
                if #colons > 2 then
                    return false
                end
                if #colons == 2 and dc == true then
                    return false
                end
                if #colons == 2 and dc == false then
                    dc = true
                end
            end
            chunk_count = chunk_count + 1
        end
        return 2 -- IPv6
    end

    return false
end

-- Parse host definition line
-- The line will have following format:
--
-- [ip]         [host] [...hosts]
--
-- This fucntion parse it and divide ip and host array,
-- And returns three values:
--   ip: stringg - ip address
--   hosts: table - mapping hosts array
--   ip_type: number - ip address type: 0:invalid, 1:ipv4, 2:ipv6
local function parse_line(line)
    local ip = nil
    local hosts = {}
    for m in line:gmatch("%S+") do
        -- If ip is nil, it's first item
        if ip == nil then
            ip = m
        else
            table.insert(hosts, m)
        end
    end

    -- Check ip format and hosts count
    local ip_type = validate_ip(ip)
    if #hosts == 0 then
        ip_type = false
    end

    return ip, hosts, ip_type
end

-- Class Definition
local Resolver = {}

-- Create resolver instance
--
-- @param string hostsfile: path to host definition file (e.g. /etc/hosts)
-- @return resolver instance table
Resolver.new = function(hostsfile)
    if not file_exists(hostsfile) then
        return nil, error("Couldn't find " .. hostsfile)
    end

    local instance = { v4 = {}, v6 = {} }
    -- Parse host line and insert to map
    for line in io.lines(hostsfile) do
        line = cleanup_line(line)
        if line:len() > 0 then
            local ip, hosts, ip_type = parse_line(line)
            if ip_type == 1 then
                for _, host in ipairs(hosts) do
                    instance.v4[host] = ip
                end
            elseif ip_type == 2 then
                for _, host in ipairs(hosts) do
                    instance.v6[host] = ip
                end
            end
        end
    end

    -- resolve() returns ip corresponds to supplied host for ipv4
    -- If host not exists in map, returns nil
    instance.resolve = function(self, host)
        return instance.v4[host]
    end

    -- resolve_v6() returns ip corresponds to supplied host for ipv6
    -- If host not exists in map, returns nil
    instance.resolve_v6 = function(self, host)
        return instance.v6[host]
    end

    return instance, nil
end

return Resolver