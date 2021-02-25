# openresty-uid

- 基于Snowflake算法思想，64bit
- 关联时间递增，同时支持时钟回拨可用


## 设计要点

组成：| 符号位 | delta时间戳 | 生产者ID(机器ID|work ID|重启次数) | 序列号 |，默认配置如下：
```text
| sign  | delta seconds | gen id | sequcne |
| 1-bit |    30-bit     | 22-bit |  11-bit |
```
- 符号位1-bit，不用
- delta时间戳：30-bit，存储秒级可以支持34年，默认以2021-01-01 00:00:00为epoch基点
- 生产者ID由机器ID、work ID、重启次数组成
  - 机器ID：7-bit可支持128个服务，通过本地文件配置
  - work ID：6-bit可支持64个线程，对应OpenResty的work.id，每个work独立一个UID生成器简化序列号递增
  - 重启次数：4-bit可尽量避免时钟回拨冲突
- 序列号：11-bit

## 吞吐量

- 每秒支持：workId * 序列号 = 17-bit，即每秒最大可生成131072个
- 每秒超过最大数量时借用未来时间

## 使用方式

### 1. 在init_by_lua_block阶段
获取并缓存本机编码ID，引用openresty.uid.luwan.machine_id_share.lua#machine_id()
- 默认文件存放目录：/tmp/uid_conf
  - 文件my_id：存放本地机器ID编码值
  - 文件reboot_num：存放启动次数

**注意：** shared缓存在nginx reload命令执行时，不会清空，因此不建议使用reload命令启动

### 2. 在init_work_by_lua_block阶段
初始化work，引用openresty.uid.luwan.generator_id_strategy.lua#idfile_reboot_strategy(my_id,reboot_num, worker_id)

### 3. 在content_by_lua_block阶段
获取uid，引用openresty.uid.luwan.uid_allocator.lua#next_uid()
