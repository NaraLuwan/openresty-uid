-- Author: L
-- Date: 2021-02-18
-- Using: 节点ID分配策略

local require = require
local tonumber = tonumber
local bit = require("bit")
local bor = bit.bor
local band = bit.band
local bnot = bit.bnot
local lshift = bit.lshift
local ngx = ngx

local _M = { version = 0.1 }


-- generator ID由：使用本地IPv4和workerId组成，
-- generator_id_bits = 22
-- sequence_bits = 11
-- delta_seconds_bits = 30
-- 不能完全解决时钟回拨问题
function _M.ipv4_strategy(machine_id, worker_id)
    local machine_id_bits = 16
    local worker_id_bits = 6

    local generator_id_bits = 22 -- machine + worker
    local sequence_bits = 11
    local delta_seconds_bits = 30

    local machine, worker = 0LL + tonumber(machine_id), tonumber(worker_id)
    local generator_id = bor(lshift(machine, worker_id_bits), worker)
    local uid_conf = {
        ['generator_id'] = generator_id,
        ['delta_seconds_bits'] = delta_seconds_bits,
        ['generator_id_bits'] = generator_id_bits,
        ['sequence_bits'] = sequence_bits
    }
    return uid_conf
end


-- generator ID由：本地ID文件，workerId， 重启次数组成
-- generator_id_bits = 19(my_id=7, worker=8, reboot_num=4)
-- sequence_bits = 14
-- delta_seconds_bits = 30
-- 能解决时钟问题
function _M.idfile_reboot_strategy(my_id, reboot_num, worker_id)
    ngx.log(ngx.NOTICE, "my_id=" .. my_id .. ", reboot=" .. reboot_num .. ", worker=" .. worker_id)
    local my_id_bits = 7
    local worker_id_bits = 8
    local reboot_num_bits = 4

    local generator_id_bits = 19 -- my_id + reboot_bum + worker_id
    local sequence_bits = 14
    local delta_seconds_bits = 30

    local id, reboot, worker = 0LL + tonumber(my_id), 0LL + tonumber(reboot_num), tonumber(worker_id)
    -- initialize max value
    local max_my_id = bnot(lshift(-1LL, my_id_bits))
    local max_worker_id = bnot(lshift(-1LL, worker_id_bits))
    local max_reboot_num = bnot(lshift(-1LL, reboot_num_bits));

    -- checkers

    if id > max_my_id then
        return nil, "Error on my_id exceeding its-bit limit: " .. my_id_bits
    end
    if worker > max_worker_id then
        return nil, "Error on worker exceeding its-bit limit: " .. worker_id_bits
    end
    -- 取模 by max_reboot_num 
    reboot = band(reboot, max_reboot_num)

    local generator_id = bor(lshift(id, reboot_num_bits + worker_id_bits), lshift(reboot, worker_id_bits), worker_id)
    local uid_conf = {
        ['generator_id'] = generator_id,
        ['delta_seconds_bits'] = delta_seconds_bits,
        ['generator_id_bits'] = generator_id_bits,
        ['sequence_bits'] = sequence_bits
    }
    return uid_conf
end

return _M