-- Author: L
-- Date: 2021-02-18
-- Using: 获取机器ID值，为16-bit数值

local require = require
local ngx = ngx
local tonumber = tonumber
local bit = require("bit")
local bor = bit.bor
local lshift = bit.lshift
local ip_util = require("utils.ip_hostname_util")
local base_util = require("utils.base_util")

local _M = { version = 0.1 }


-- 获取本机机器ID，16-bit
-- 使用IPv4的最后两位
function _M.id_from_ipv4()

    local ipv4 = ip_util.get_ipv4()
    if (not ipv4) then
        return nil
    end
    local a, b, c, d = ipv4:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
    if not a then
        return nil
    end
    c, d = tonumber(c), tonumber(d)
    -- 合并为16bit数值
    local machine_id = bor(lshift(c, 8), d)
    ngx.log(ngx.NOTICE, "==== Gen machine id: " .. machine_id)
    return machine_id
end

-- 获取本机机器ID，7-bit，最大127个
-- 使用ID文件中的定义ID值 
function _M.id_from_identity_file(id_file)
    local is_exist = base_util.is_file_exist(id_file)
    if not is_exist then
        ngx.log(ngx.ERR, "==== There is no id_file: " .. id_file)
        -- 期望服务退出
    end

    local id = base_util.read_file(id_file)
    if not id then
        ngx.log(ngx.ERR, "==== Failed to get id from id_file: " .. id_file)
        -- 期望服务退出
    end
    return id
end

-- 获取重启次数
function _M.fetch_reboot_num(reboot_num_file)

    local reboot_num = base_util.read_file(reboot_num_file)
    if not reboot_num then
        reboot_num = 0
        ngx.log(ngx.NOTICE, "==== Failed to get reboot_num from file: " .. reboot_num_file)
    end
    base_util.write_file(reboot_num_file, (reboot_num + 1))
    return reboot_num

end

return _M

