#!/usr/bin/env lua5.3

--FC_DIR = error 'set absolute path to "<freechains>" repository'
FC_DIR = '/data/ceu/ceu-libuv/ceu-libuv-freechains'
dofile(FC_DIR..'/src/common.lua')

local HASH_BYTES = 32

local url = assert((...))

--local log = assert(io.open('/tmp/log.txt','a+'))
local log = io.stderr
log:write('URL: '..url..'\n')

if string.sub(url,1,13) ~= 'freechains://' then
    os.execute('xdg-open '..url)
    os.exit(0)
end

local function ASR (cnd, msg)
    msg = msg or 'malformed command'
    if not cnd then
        io.stderr:write('ERROR: '..msg..'\n')
        os.exit(1)
    end
    return cnd
end

--[[
freechains://?cmd=publish&cfg=/data/ceu/ceu-libuv/ceu-libuv-freechains/cfg/config-8400.lua
freechains::-1?cmd=publish&cfg=/data/ceu/ceu-libuv/ceu-libuv-freechains/cfg/config-8400.lua

freechains://<address>:<port>/<chain>/<work>/<hash>?

]]

local address, port, res = string.match(url, 'freechains://([^:]*):([^/]*)/(.*)')
--print(address , port , res)
ASR(address and port and res)
log:write('URL: '..res..'\n')

DAEMON = {
    address = address,
    port    = ASR(tonumber(port)),
}
daemon = DAEMON.address..':'..DAEMON.port

CFG = FC.send(0x0500, nil, DAEMON)
--print('>>>', tostring2(CFG,'plain'))

-- new
if not cmd then
    cmd = string.match(res, '^?cmd=(new)')
end

-- subscribe
if not cmd then
    key, cmd = string.match(res, '^([^/]*)/%?cmd=(subscribe)')
end
if not cmd then
    key, cmd, address, port = string.match(res, '^([^/]*)/%?cmd=(subscribe)&peer=(.*):(.*)')
end

-- publish
if not cmd then
    key, cmd = string.match(res, '^([^/]*)/%?cmd=(publish)')
end

-- republish
if not cmd then
    key, zeros, pub, cmd = string.match(res, '^([^/]*)/([^/]*)/([^/]*)/%?cmd=(republish)')
end

-- removal
if not cmd then
    key, zeros, block, cmd = string.match(res, '^([^/]*)/([^/]*)/([^/]*)/%?cmd=(removal)')
end

-- atom
if not cmd then
    key, cmd = string.match(res, '^(.*)/%?cmd=(atom)')
end

log:write('INFO: .'..cmd..'.\n')

if cmd=='new' or cmd=='subscribe' then
    -- get key
    if cmd == 'new' then
        local f = io.popen('zenity --entry --title="New Chain" --text="Chain Identifier:"')
        key = f:read('*a')
        key = string.sub(key,1,-2)
        local ok = f:close()
        if not ok then
            log:write('ERR: '..key..'\n')
            goto END
        end

        -- get description
        local f = io.popen('zenity --entry --title="New Chain" --text="Chain Description:" --entry-text="Awesome chain!"')
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
        local chain = CFG.chains[key]
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
    FC.send(0x0400, {
        chain = {
            key   = key,
            zeros = assert(tonumber(zeros)),
            peers = peers,
        }
    }, DAEMON)

    -- publish announcement to //0/

    local was_sub = CFG.chains[key]
    if not was_sub then
        payload = ''
        if cmd == 'new' then
            payload = [[
New chain "]]..key..[[":

> ]]..description..[[


Subscribe to []]..key..[[](freechains:/]]..key..[[/?cmd=subscribe&peer=]]..daemon..[[).
]]
        else
            payload = [[
I'm also subscribed to chain "]]..key..[[".

Subscribe to []]..key..[[](freechains:/]]..key..[[/?cmd=subscribe&peer=]]..daemon..[[).
]]
        end

        local msg = {
            chain = {
                key   = '',
                zeros = 0,
            },
            payload = payload,
        }
        FC.send(0x0300, msg, DAEMON)

        if cmd == 'new' then
            local exe = 'dbus-send --session --dest=org.gnome.feed.Reader --type=method_call /org/gnome/feed/Reader org.gnome.feed.Reader.Subscribe "string:|freechains-liferea freechains://'..daemon..'/'..key..'/?cmd=atom"'
            --print('>>>', exe)
            os.execute(exe)
        end
    end

elseif cmd == 'publish' then
    local f = io.popen('zenity --text-info --editable --title="Publish to '..key..'/"')
    local payload = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..payload..'\n')
        goto END
    end

    local zeros = assert(CFG.chains[key]).zeros
    local f = io.popen('zenity --entry --title="Publish to '..key..'/" --text="Amount of Work:" --entry-text='..zeros)
    zeros = f:read('*a')
    local ok = f:close()
    if not ok then
        log:write('ERR: '..zeros..'\n')
        goto END
    end
    zeros = string.sub(zeros,1,-2)

    FC.send(0x0300, {
        chain = {
            key   = key,
            zeros = assert(tonumber(zeros)),
        },
        payload = payload,
    }, DAEMON)

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

    local ret = FC.send(0x0200, {
        chain = {
            key   = old_key,
            zeros = assert(tonumber(old_zeros)),
        },
        pub = pub,
    }, DAEMON)
    FC.send(0x0300, {
        chain = {
            key   = new_key,
            zeros = assert(tonumber(new_zeros)),
        },
        -- TODO: timestamp if nonce reached maximum
        nonce = (new_key==old_key and ret.nonce) or nil,
        payload = ret.pub.payload,
    }, DAEMON)

elseif cmd == 'removal' then
    FC.send(0x0300, {
        chain = {
            key   = key,
            zeros = assert(tonumber(zeros)),
        },
        removal = block,
    }, DAEMON)

elseif cmd == 'atom' then
    TEMPLATES =
    {
        feed = [[
            <feed xmlns="http://www.w3.org/2005/Atom">
                <title>__TITLE__</title>
                <updated>__UPDATED__</updated>
                <id>
                    freechains:/__CHAIN_ID__/
                </id>
            __ENTRIES__
            </feed>
        ]],
        entry = [[
            <entry>
                <title>__TITLE__</title>
                <id>
                    freechains:/__CHAIN_ID__/__HASH__/
                </id>
                <published>__PUBLISHED__</published>
                <content type="html">__CONTENT__</content>
            </entry>
        ]],
    }

    -- TODO: hacky, "plain" gsub
    gsub = function (a,b,c)
        return string.gsub(a, b, function() return c end)
    end

    CHAIN = CFG.chains[key]
    if not CHAIN then
        entries = {}
        entry = TEMPLATES.entry
        entry = gsub(entry, '__TITLE__',     'not subscribed')
        entry = gsub(entry, '__CHAIN_ID__',  key)
        entry = gsub(entry, '__HASH__',      string.rep('00', 32))
        entry = gsub(entry, '__PUBLISHED__', os.date('!%Y-%m-%dT%H:%M:%SZ', os.time()))
        entry = gsub(entry, '__CONTENT__',   'not subscribed')
        entries[#entries+1] = entry
    else
        entries = {}

        for i=CHAIN.zeros, 255 do
            head = FC.send(0x0200, {
                chain = { key=CHAIN.key, zeros=i },
            }, DAEMON)
            if not head then
                goto i_continue
            end
            cur = head
            while cur.prv~=nil and cur.hash~=CHAIN.last.atom[i] do
                if not cur.pub then
                    goto cur_continue
                end
                payload = (cur.pub.payload or ('Removed publication: '..cur.pub.removal))

                title = FC.escape(string.match(payload,'([^\n]*)'))

                if cur.pub.payload then
                    payload = payload .. [[


-------------------------------------------------------------------------------

- [X](freechains:/]]..CHAIN.key..'/'..i..'/'..cur.pub.hash..[[/?cmd=republish)
Republish Contents
- [X](freechains:/]]..CHAIN.key..'/'..i..'/'..cur.hash..[[/?cmd=removal)
Inappropriate Contents
]]
                end

                -- freechains links
                payload = string.gsub(payload, '(%[.-%]%(freechains:)(/.-%))', '%1//'..daemon..'%2')

                -- markdown
--if false then
                do
                    local tmp = os.tmpname()
                    local md = assert(io.popen('pandoc -r markdown -w html > '..tmp, 'w'))
                    md:write(payload)
                    assert(md:close())
                    local html = assert(io.open(tmp))
                    payload = html:read('*a')
                    html:close()
                    os.remove(tmp)
                end
--end

                payload = FC.escape(payload)

                entry = TEMPLATES.entry
                entry = gsub(entry, '__TITLE__',     '['..i..'] '..title)
                entry = gsub(entry, '__CHAIN_ID__',  CHAIN.key..'/'..i)
                entry = gsub(entry, '__HASH__',      cur.hash)
                entry = gsub(entry, '__PUBLISHED__', os.date('!%Y-%m-%dT%H:%M:%SZ', cur.pub.timestamp/1000000))
                entry = gsub(entry, '__CONTENT__',   payload)
                entries[#entries+1] = entry

                ::cur_continue::
                cur = FC.send(0x0200, {
                    chain = { key=CHAIN.key, zeros=i },
                    block = cur.prv,
                }, DAEMON)
            end
            if head.prv ~= nil then  -- avoids polluting the cfg
                CHAIN.last.atom[i] = head.hash
            end
            ::i_continue::
        end
        FC.send(0x0500, CFG, DAEMON)

        -- MENU
        do
            entry = TEMPLATES.entry
            entry = gsub(entry, '__TITLE__',     'Menu')
            entry = gsub(entry, '__CHAIN_ID__',  CHAIN.key)
            entry = gsub(entry, '__HASH__',      FC.hash2hex(string.rep('\0',32)))
            entry = gsub(entry, '__PUBLISHED__', os.date('!%Y-%m-%dT%H:%M:%SZ', 25000))
            entry = gsub(entry, '__CONTENT__',   FC.escape([[
<ul>
]]..(CHAIN.key~='' and '' or [[
<li> <a href="freechains://]]..daemon..[[/?cmd=new">[X]</a> New Chain
]])..[[
<li> <a href="freechains://]]..daemon..[[/]]..CHAIN.key..[[/?cmd=subscribe">[X]</a> Change Minimum Work for "]]..CHAIN.key..[["
<li> <a href="freechains://]]..daemon..[[/]]..CHAIN.key..[[/?cmd=publish">[X]</a> Publish to "]]..CHAIN.key..[["
</ul>
]]))
            entries[#entries+1] = entry
        end
    end

    feed = TEMPLATES.feed
    feed = gsub(feed, '__TITLE__',    (key=='' and '/' or key))
    feed = gsub(feed, '__UPDATED__',  os.date('!%Y-%m-%dT%H:%M:%SZ', os.time()))
    feed = gsub(feed, '__CHAIN_ID__', key)
    feed = gsub(feed, '__ENTRIES__',  table.concat(entries,'\n'))

    f = io.stdout --assert(io.open(dir..'/'..key..'.xml', 'w'))
    f:write(feed)
    goto END

end

::OK::
os.execute('zenity --info --text="OK"')
goto END

::ERROR::
os.execute('zenity --error')

::END::

log:close()
