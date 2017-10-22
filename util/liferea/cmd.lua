#!/usr/bin/env lua5.3

dofile '/data/ceu/ceu-libuv/ceu-libuv-freechains/src/common.lua'

local url = string.match((...), 'freechains:(.*)')
if not url then
    os.execute('xdg-open '..(...))
    os.exit(0)
end

local log = assert(io.open('/tmp/log.txt','a+'))
log:write(url..'\n')

key, zeros, cmd, cfg = string.match(url, '/|(.*)|(.*)|/%?cmd=(.*)&cfg=(.*)')
if cmd then
    log:write('INFO: '..key..','..zeros..','..cmd..','..cfg..'\n')
else
    publication, cmd, old_id, cfg = string.match(url, '(.*)/%?cmd=(.*)&old=(.*)&cfg=(.*)')
    log:write('INFO: '..publication..','..cmd..','..old_id..','..cfg..'\n')
end

local CFG = {}
assert(loadfile(cfg,nil,CFG))()

log:write('INFO: .'..cmd..'.\n')
if cmd == 'publish' then
    local f = io.popen('zenity --text-info --editable --title "Publish to |'..key..'|'..zeros..'|"')
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
elseif cmd == 'republish' then
    local f = io.popen('zenity --entry --title="Republish Contents" --text="Enter the new Chain ID:" --entry-text="'..old_id..'"')

    local new_id = f:read('*a')
    local key,zeros = string.match(new_id,'|(.*)|(.*)|')
    local new = { key=key, zeros=tonumber(zeros) }
    local key,zeros = string.match(old_id,'|(.*)|(.*)|')
    local old = { key=key, zeros=tonumber(zeros) }

    local ok = f:close()
    if ok and new_id~=old_id then
        local t = {
            cmd = 'republish',
            hash = FC.hex2hash(publication),
            old = old,
            new = new,
        }
        local str = tostring2(t, 'plain')

        local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
        f:write(tostring(string.len(str))..'\n'..str)
        f:close()
    else
        log:write('ERR: '..new_id..'\n')
    end
end

log:close()
