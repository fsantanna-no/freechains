#!/usr/bin/env lua5.3

dofile '/data/ceu/ceu-libuv/ceu-libuv-freechains/src/common.lua'

local url = string.match((...), 'freechains:(.*)')
if not url then
    os.execute('xdg-open '..(...))
    os.exit(0)
end

local log = assert(io.open('/tmp/log.txt','a+'))
log:write(url..'\n')

local key, zeros, cmd, cfg = string.match(url, '/|(.*)|(.*)|/%?cmd=(.*)&cfg=(.*)')
log:write('INFO: '..key..','..zeros..','..cmd..','..cfg..'\n')

local CFG = {}
assert(loadfile(cfg,nil,CFG))()

log:write('INFO: .'..cmd..'.\n')
if cmd == 'publish' then
    local f = io.popen('zenity --text-info --editable --title "Publish to |'..key..'|'..zeros..'|"')
    log:write('INFO: '..tostring(f)..'\n')
    local payload = f:read('*a')
    local ok = f:close()
    if ok then
        local t = {
            cmd = 'publish',
            message = {
                version = '1.0',
                chain = {
                    key = key,
                    zeros = assert(tonumber(zeros)),
                },
                payload = payload,
            },
        }
        local str = tostring2(t, 'plain')

        local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
        f:write(tostring(string.len(str))..'\n'..str)
        f:close()
    else
        log:write('ERR: '..payload..'\n')
    end
end

log:close()
