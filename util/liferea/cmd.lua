#!/usr/bin/env lua5.3

local log = assert(io.open('/tmp/log.txt','a+'))
log:write((...)..'\n')

FC_DIR = error 'set absolute path to "<freechains>" repository'
dofile(FC_DIR..'/src/common.lua')

--[[
freechains://?cmd=publish&cfg=/data/ceu/ceu-libuv/ceu-libuv-freechains/cfg/config-8400.lua
freechains::-1?cmd=publish&cfg=/data/ceu/ceu-libuv/ceu-libuv-freechains/cfg/config-8400.lua

]]

local url = string.match((...), 'freechains:(.*)')
if not url then
    os.execute('xdg-open '..(...))
    os.exit(0)
end

log:write(url..'\n')

-- new
if not cmd then
    cmd, cfg = string.match(url, '^/%?cmd=(new)&cfg=(.*)')
end

-- subscribe
if not cmd then
    -- TODO: bug in Liferea?
    cmd, cfg = string.match(url, '^:%-1%?cmd=(subscribe)&cfg=(.*)')
    key = ''
end
if not cmd then
    key, cmd, cfg = string.match(url, '^/(.*)/%?cmd=(subscribe)&cfg=(.*)')
end
if not cmd then
    key, cmd, address, port, cfg = string.match(url, '^/(.*)/%?cmd=(subscribe)&peer=(.*):(.*)&cfg=(.*)')
end

-- publish
if not cmd then
    -- TODO: bug in Liferea?
    cmd, cfg = string.match(url, '^:%-1%?cmd=(publish)&cfg=(.*)')
    key = ''
end
if not cmd then
    key, cmd, cfg = string.match(url, '^/(.*)/%?cmd=(publish)&cfg=(.*)')
end

-- republish
if not cmd then
    key, zeros, pub, cmd, cfg = string.match(url, '^/(.*)/(.*)/(.*)/%?cmd=(republish)&cfg=(.*)')
end

-- removal
if not cmd then
    key, zeros, block, cmd, cfg = string.match(url, '^/(.*)/(.*)/(.*)/%?cmd=(removal)&cfg=(.*)')
end

log:write('INFO: .'..cmd..'.\n')

CFG = {}
assert(loadfile(cfg,nil,CFG))()

if cmd=='new' or cmd=='subscribe' then
    -- get key
    if cmd == 'new' then
        local f = io.popen('zenity --entry --title="New Chain" --text="Enter the Chain Key:"')
        key = f:read('*a')
        key = string.sub(key,1,-2)
        local ok = f:close()
        if not ok then
            log:write('ERR: '..key..'\n')
            goto END
        end

        -- get description
        local f = io.popen('zenity --entry --title="New Chain" --text="Enter the Chain Description:" --entry-text="Awesome chain!"')
        description = f:read('*a')
        description = string.sub(description,1,-2)
        ok = f:close()
        if not ok then
            log:write('ERR: '..description..'\n')
            goto END
        end
    end

    -- get zeros
    zeros = 0
    if cmd == 'subscribe' then
        local chain = FC.cfg_chain(key)
        zeros = chain and chain.zeros or 0
        local f = io.popen('zenity --entry --title="Subscribe to '..key..'/" --text="Minimum Amount of Work:" --entry-text='..zeros)
        zeros = f:read('*a')
        local ok = f:close()
        if not ok then
            log:write('ERR: '..zeros..'\n')
            goto END
        end
        zeros = string.sub(zeros,1,-2)
    end

    -- get peers
    peers = {}
    if cmd=='subscribe' and address and port then
        peers = {
            [1] = {
                address = address,
                port    = assert(tonumber(port)),
            }
        }
    end

    -- subscribe
    local t = {
        cmd = 'subscribe',
        chain = {
            key   = key,
            zeros = assert(tonumber(zeros)),
            peers = peers,
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

    -- publish announcement to //0/

    local was_sub = FC.cfg_chain(key)
    if not was_sub then
        payload = ''
        if cmd == 'new' then
            payload = [[
New chain "]]..key..[[":

> ]]..description..[[


Subscribe to []]..key..[[](freechains:/]]..key..[[/?cmd=subscribe&peer=]]..(CFG.server.address or 'localhost')..':'..(CFG.server.port or 8400)..[[).
]]
        else
            payload = [[
I'm also subscribed to chain "]]..key..[[".

Subscribe to []]..key..[[](freechains:/]]..key..[[/?cmd=subscribe&peer=]]..(CFG.server.address or 'localhost')..':'..(CFG.server.port or 8400)..[[).
]]
        end

        local t = {
            cmd = 'publish',
            message = {
                version = '1.0',
                chain = {
                    key   = '',
                    zeros = 0,
                },
                payload = payload,
            },
        }
        local str = tostring2(t, 'plain')
        local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
        f:write(tostring(string.len(str))..'\n'..str)
        f:close()
    end

elseif cmd == 'publish' then
    local f = io.popen('zenity --text-info --editable --title="Publish to '..key..'/"')
    local payload = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..payload..'\n')
        goto END
    end

    local zeros = assert(FC.cfg_chain(key)).zeros
    local f = io.popen('zenity --entry --title="Publish to '..key..'/" --text="Amount of Work:" --entry-text='..zeros)
    zeros = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..zeros..'\n')
        goto END
    end
    zeros = string.sub(zeros,1,-2)

    local t = {
        cmd = 'publish',
        message = {
            version = '1.0',
            chain = {
                key   = key,
                zeros = assert(tonumber(zeros)),
            },
            payload = payload,
        },
    }
    local str = tostring2(t, 'plain')

    local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
    f:write(tostring(string.len(str))..'\n'..str)
    f:close()

elseif cmd == 'republish' then
    local old_key   = key
    local old_zeros = zeros
    local f = io.popen('zenity --entry --title="Republish Contents" --text="Enter the Chain Key:" --entry-text="'..old_key..'"')
    local new_key = f:read('*a')
log:write('>>>.'..new_key..'.\n')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..new_key..'\n')
        goto END
    end
    new_key = string.sub(new_key,1,-2)
log:write('>>>.'..new_key..'.\n')

    local f = io.popen('zenity --entry --title="Republish to '..new_key..'/" --text="Amount of Work:" --entry-text="'..old_zeros..'"')
    local new_zeros = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..new_zeros..'\n')
        goto END
    end
    new_zeros = string.sub(new_zeros,1,-2)

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
    local t = {
        cmd = 'publish',
        message = {
            version = '1.0',
            chain = {
                key   = key,
                zeros = assert(tonumber(zeros)),
            },
            removal = FC.hex2hash(block),
        },
    }
    local str = tostring2(t, 'plain')

    local f = assert(io.open(CFG.dir..'/fifo.in', 'a+'))
    f:write(tostring(string.len(str))..'\n'..str)
    f:close()

end

::OK::
os.execute('zenity --info --text="OK"')
goto END

::ERROR::
os.execute('zenity --error')

::END::

log:close()
