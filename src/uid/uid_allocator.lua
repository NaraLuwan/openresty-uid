-- Author: L
-- Date: 2021-02-18
-- Using: UID生成器
--        默认情况下：
--        | sign | delta seconds | gen id | sequcne |
--        | 1-bit | 30-bit | 22-bit | se11-bit |

local require = require
local ngx = ngx
local bit = require("bit")
local lshift = bit.lshift
local bnot = bit.bnot
local bor = bit.bor

local _M = { version = 0.1 }

local TOTAL_BITS = 64 -- 64bit
-- Bits for [sign-> delta seconds -> gen Id-> sequence]

local SIGN_BITS_DEFAULT = 1
local DELTA_SEONCDS_BITS_DEFAULT = 30
local GENERATOR_BITS_DEFAULT = 19
local SEQ_BITS_DEFAULT = 14

local delta_seconds_bits
local generator_id_bits
local sequence_bits

-- Custom epoch, unit as second. For example 2021-01-01 00:00:00 (ms: 1609430400000)*/
local epoch_seconds = 1609430400LL

local max_delta_seconds
local max_generator_id
local max_sequence

local delta_seconds_shift
local generator_id_shift

local generator_id = 0LL
local sequence = 0LL
local last_second = -1LL

--
-- 初始化UID生成器
-- conf 参数如下
--     delta_seconds_bits 可选，时间戳位数
--     generator_id_bits 可选，workId位数 
--     sequence_bits 可选，序号位数 
--     generator_id 必填，work ID 
--
function _M.init(conf)
    if not conf then
        return false, "conf参数不能为空"
    end
    if not conf.generator_id then
        return false, "参数generator_id必填，不能为空"
    end

    -- initialize bits
    delta_seconds_bits = conf.delta_seconds_bits or DELTA_SEONCDS_BITS_DEFAULT
    generator_id_bits = conf.generator_id_bits or GENERATOR_BITS_DEFAULT
    sequence_bits = conf.sequence_bits or SEQ_BITS_DEFAULT
    -- make sure allocated 64 bits
    local allocate_total_bits = SIGN_BITS_DEFAULT + delta_seconds_bits + generator_id_bits + sequence_bits
    if TOTAL_BITS ~= allocate_total_bits then
        return false, "Allocated size of bits is not 64-bit"
    end

    -- initialize shift
    delta_seconds_shift = generator_id_bits + sequence_bits
    generator_id_shift = sequence_bits

    -- initialize max value
    max_delta_seconds = bnot(lshift(-1LL, delta_seconds_bits))
    max_generator_id = bnot(lshift(-1LL, generator_id_bits))
    max_sequence = bnot(lshift(-1LL, sequence_bits));

    -- checkers

    if conf.generator_id > max_generator_id then
        return false, "Error on generator_id id exceeding its-bit limit"
    end
    -- init service ids
    generator_id = lshift(0LL + conf.generator_id, generator_id_shift)
    ngx.log(ngx.NOTICE, "==== uid_allocator inited done: generator_id=" .. tostring(generator_id))
    return true
end

function _M.next_uuid()
    local current_second = ngx.time()
    -- 调整判断：时间戳，sequence初始值
    if last_second < current_second then
        last_second = current_second
        sequence = 0LL
    end
    if sequence > max_sequence then
        last_second = last_second + 1
        sequence = 0LL
    end
    -- 下一个uid，单work上安全递增
    local current_sequence = sequence
    sequence = sequence + 1
    local current_delta_seconds = 0LL + (last_second - epoch_seconds)
    -- snowflake uid 构造
    local uuid = bor(lshift(current_delta_seconds, delta_seconds_shift), generator_id, current_sequence)
    return uuid
end

return _M