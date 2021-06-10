-- Author: L
-- Date: 2021-02-18
-- 每个worker初始化

local require = require
local ngx = ngx
local constants = require("uid.core.constants")

local _M = { version = 0.1 }

local function init_machine_id()
    local machine_id_gen = require("uid.core.machine_id")
    local machine_id = machine_id_gen.id_from_ipv4()
    ngx.log(ngx.NOTICE, "==== Machine_id: " .. machine_id)
    if not machine_id then
        ngx.err(ngx.ERR, "==== Error on no valid machine_id, then os.exit(1)")
        os.exit(1)
    end

    local my_id = machine_id_gen.id_from_identity_file(constants.UID_CONF_MY_ID_FILE)
    if not my_id then
        ngx.err(ngx.ERR, "==== Error on no my_id founded, then os.exit(1)")
        os.exit(1)
    end

    local reboot_num = machine_id_gen.fetch_reboot_num(constants.UID_CONF_ROOBOOT_NUM_FILE)
    if not reboot_num then
        ngx.err(ngx.ERR, "==== Error on no reboot_num founded, then os.exit(1)")
        os.exit(1)
    end

    local machine_id_cache = ngx.shared.machine_id_cache
    machine_id_cache:set(constants.CACHE_MACHINE_ID_K, machine_id)
    machine_id_cache:set(constants.CACHE_MY_ID_K, my_id)
    machine_id_cache:set(constants.CACHE_REBOOT_NUM_K, reboot_num)
end

local function init_allocator()
    local machine_id_cache = ngx.shared.machine_id_cache
    local my_id = machine_id_cache:get(constants.CACHE_MY_ID_K)
    local reboot_num = machine_id_cache:get(constants.CACHE_REBOOT_NUM_K)
    local worker_id = ngx.worker.id()

    local gen_strategy = require("uid.core.generator_strategy")
    local uid_conf = gen_strategy.idfile_reboot_strategy(my_id, reboot_num, worker_id)

    local uid_allocator = require("uid.core.allocator")
    uid_allocator.init(uid_conf)
end

function _M.init()
    init_machine_id()
    init_allocator()
end

return _M