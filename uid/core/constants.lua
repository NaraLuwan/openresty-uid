-- @author L

local _M = { VERSION = 0.1 }

-- UID配置目录及文件
_M.UID_CONF_DIR = "/home/luwan/uid_conf"
_M.UID_CONF_MY_ID_FILE = _M.UID_CONF_DIR .. "/my_id"
_M.UID_CONF_ROOBOOT_NUM_FILE = _M.UID_CONF_DIR .. "/reboot_num"

-- cache key
_M.CACHE_MACHINE_ID_K = "uid.machine_id"
_M.CACHE_MY_ID_K = "uid.my_id"
_M.CACHE_REBOOT_NUM_K = "uid.reboot_num"

return _M