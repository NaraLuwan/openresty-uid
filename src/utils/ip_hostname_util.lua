-- Author: NaraLuwan
-- Date: 2021-02-18
-- Using: 获取IPv4和hostname

local require = require
local io = io
local io_popen = io.popen
local sub_str = string.sub
local string_util = require("utils.string_util")
local local_resolver = require("utils.local_ip_resolver")

local _M = { version = 0.1 }

local hostname
local ipv4

-- 获取主机名, /bin/hostname
-- 注意: 只能在init_by_lua, init_worker_by_lua中使用
function _M.get_hostname()
    if hostname then
        return hostname
    end

    local hd = io_popen("/bin/hostname")
    local data, err = hd:read("*a")
    if err == nil then
        hostname = data
        if string_util.has_suffix(hostname, "\r\n") then
            hostname = sub_str(hostname, 1, -3)
        elseif string_util.has_suffix(hostname, "\n") then
            hostname = sub_str(hostname, 1, -2)
        end

    else
        hostname = nil
    end

    return hostname
end

-- 获取IPv4, /etc/hosts
-- 注意: 只能在init_by_lua, init_worker_by_lua中使用
function _M.get_ipv4()
    if ipv4 then
        return ipv4
    end
    local hostname = _M.get_hostname()
    if not hostname or hostname == '' or hostname == 'unknown' then
        return nil
    end
    local resolver = local_resolver.new("/etc/hosts")
    local ip = resolver:resolve(hostname)
    return ip
end

return _M