#!/usr/bin/env lua5.3

dofile '/data/ceu/ceu-libuv/ceu-libuv-freechains/src/common.lua'

--[[
freechains://?cmd=publish&cfg=/data/ceu/ceu-libuv/ceu-libuv-freechains/cfg/config-8400.lua
freechains::-1?cmd=publish&cfg=/data/ceu/ceu-libuv/ceu-libuv-freechains/cfg/config-8400.lua

]]

local log = assert(io.open('/tmp/log.txt','a+'))
log:write((...)..'\n')

local url = string.match((...), 'freechains:(.*)')
if not url then
    os.execute('xdg-open '..(...))
    os.exit(0)
end

log:write(url..'\n')

-- main menu
if not cmd then
    cmd, cfg = string.match(url, '%?cmd=(menu)&cfg=(.*)')
end

-- subscribe
if not cmd then
    cmd, cfg     = string.match(url, '%?cmd=(subscribe)&cfg=(.*)')
end
if not cmd then
    cmd, key, cfg = string.match(url, '^/%?cmd=(subscribe)&key=(.*)&cfg=(.*)')
end

-- publish
if not cmd then
    key, cmd, cfg = string.match(url, '^/(.*)/%?cmd=(publish)&cfg=(.*)')
end

-- republish
if not cmd then
    key, pub, cmd, cfg = string.match(url, '^/(.*)/(.*)/%?cmd=(republish)&old=(.*)&cfg=(.*)')
end

-- removal
if not cmd then
    key, zeros, block, cmd, cfg = string.match(url, '^/(.*)/(.*)/(.*)/%?cmd=(removal)&cfg=(.*)')
end

log:write('INFO: .'..cmd..'.\n')

local CFG = {}
assert(loadfile(cfg,nil,CFG))()

if cmd == 'menu' then
    print ([[
<?xml version="1.0" encoding="utf-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">

            <title>Freechains</title>
        <!--
            <link href="freechains:"/>
        -->
            <id>http://www.freechains.org/"</id>

            <entry>
                <title>Main Menu</title>
                <id>http://www.freechains.org/main-menu</id>
                <updated>1970-01-02T00:00:00Z</updated>
                <content type="html">]]..FC.escape([[
                    <ul>
                        <li> <a href="freechains:/?cmd=subscribe&cfg=]]..cfg..[[">[X]</a> Subscribe to Chain
                    </ul>]])..[[
                </content>
            </entry>
        </feed>
    ]])
    os.exit(0)

elseif cmd == 'subscribe' then
    local ok = true

    if not key then
        local f = io.popen('zenity --entry --title="Subscribe to Chain" --text="Enter the Chain Key:"')
        key = f:read('*a')
        ok = f:close()
    end
    key = string.sub(key,1,-2)

    local f = io.popen('zenity --entry --title="Subscribe to '..key..'/" --text="Minimum Amount of Work:" --entry-text=0')
    local zeros = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..zeros..'\n')
        return
    end
    zeros = string.sub(zeros,1,-2)
    zeros = assert(tonumber(zeros))

    if ok then
        local t = {
            cmd = 'subscribe',
            chain = {
                key   = key,
                zeros = zeros,
                peers = {},
                last  = {
                    output = {},
                    atom   = {},
                },
            }
        }
        local str = tostring2(t, 'plain')

        local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
        f:write(tostring(string.len(str))..'\n'..str)
        f:close()
    else
        log:write('ERR: '..key..'\n')
    end

elseif cmd == 'publish' then
    local f = io.popen('zenity --text-info --editable --title="Publish to '..key..'/"')
    local payload = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..payload..'\n')
        return
    end

    local f = io.popen('zenity --entry --title="Publish to '..key..'/" --text="Amount of Work:" --entry-text=0')
    local zeros = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..zeros..'\n')
        return
    end
    zeros = string.sub(zeros,1,-2)
    zeros = assert(tonumber(zeros))

    local t = {
        cmd = 'publish',
        message = {
            version = '1.0',
            chain = {
                key   = key,
                zeros = zeros,
            },
            payload = payload,
        },
    }
    local str = tostring2(t, 'plain')

    local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
    f:write(tostring(string.len(str))..'\n'..str)
    f:close()

elseif cmd == 'republish' then
    local old_key = key
    local f = io.popen('zenity --entry --title="Republish Contents" --text="Enter the Chain Key:" --entry-text="'..old_key..'"')
    local new_key = f:read('*a')
log:write('>>>.'..new_key..'.\n')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..new_key..'\n')
        return
    end
    new_key = string.sub(new_key,1,-2)

    local f = io.popen('zenity --entry --title="Republish to '..new_key..'/" --text="Amount of Work:" --entry-text="'..old_zeros..'"')
    local new_zeros = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..new_zeros..'\n')
        return
    end
    new_zeros = string.sub(new_zeros,1,-2)
    new_zeros = assert(tonumber(new_zeros))

    local t = {
        cmd = 'republish',
        hash = FC.hex2hash(pub),
        old = {
            key   = old_key,
            zeros = assert(tonumber(old_zeros)),
        },
        new = {
            key   = new_key,
            zeros = assert(tonumber(new_zeros)),
        },
    }

    local str = tostring2(t, 'plain')
    local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
    f:write(tostring(string.len(str))..'\n'..str)
    f:close()

elseif cmd == 'removal' then
    zeros = assert(tonumber(zeros))
    local t = {
        cmd = 'publish',
        message = {
            version = '1.0',
            chain = {
                key   = key,
                zeros = zeros,
            },
            removal = FC.hex2hash(block),
        },
    }
    local str = tostring2(t, 'plain')

    local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
    f:write(tostring(string.len(str))..'\n'..str)
    f:close()

end

log:close()
