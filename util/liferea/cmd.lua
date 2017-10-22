#!/usr/bin/env lua5.3

dofile '/data/ceu/ceu-libuv/ceu-libuv-freechains/src/common.lua'

local url = string.match((...), 'freechains:(.*)')
if not url then
    os.execute('xdg-open '..(...))
    os.exit(0)
end

local log = assert(io.open('/tmp/log.txt','a+'))
log:write(url..'\n')

-- main menu
if not cmd then
    cmd, cfg = string.match(url, '/%?cmd=(menu)&cfg=(.*)')
end

-- subscribe
if not cmd then
    cmd, cfg     = string.match(url, '/%?cmd=(subscribe)&cfg=(.*)')
end
if not cmd then
    cmd, id, cfg = string.match(url, '/%?cmd=(subscribe)&id=(.*)&cfg=(.*)')
end

-- publish
if not cmd then
    key, zeros, cmd, cfg = string.match(url, '/|(.*)|(.*)|/%?cmd=(publish)&cfg=(.*)')
end

-- republish
if not cmd then
    pub, cmd, old_id, cfg = string.match(url, '(.*)/%?cmd=(republish)&old=(.*)&cfg=(.*)')
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
                        <li> <a href="freechains:/?cmd=subscribe&cfg=]]..cfg..[[">[X]</a> Subscribe to new chain.
                    </ul>]])..[[
                </content>
            </entry>
        </feed>
    ]])
    os.exit(0)

elseif cmd == 'subscribe' then
    local ok = true

    if not id then
        local f = io.popen('zenity --entry --title="Subscribe to Chain" --text="Enter the Chain ID:"')
        id = f:read('*a')
        ok = f:close()
    end

    if ok then
        local key,zeros = string.match(id,'|(.*)|(.*)|')
        local t = {
            cmd = 'subscribe',
            chain = {
                key = key,
                zeros = tonumber(zeros),
                last  = {
                    output = {},
                    atom   = {},
                },
                peers = {},
            }
        }
        local str = tostring2(t, 'plain')

        local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
        f:write(tostring(string.len(str))..'\n'..str)
        f:close()
    else
        log:write('ERR: '..id..'\n')
    end

elseif cmd == 'publish' then
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
            hash = FC.hex2hash(pub),
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
