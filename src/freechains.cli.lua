#!/usr/bin/env lua5.3

--FC_DIR = error 'set absolute path to "<freechains>" repository'
FC_DIR = '/data/ceu/ceu-libuv/ceu-libuv-freechains'
dofile(FC_DIR..'/src/common.lua')

local optparse = dofile 'src/optparse.lua'

local function ASR (cnd, msg)
    msg = msg or 'malformed command'
    if not cnd then
        io.stderr:write('ERROR: '..msg..'\n')
        os.exit(1)
    end
    return cnd
end

local help = [[
freechains 0.1

Usage: freechains [<options>] <command> <arguments>

Commands:

    # DAEMON

    Starts a freechain daemon.

    $ freechains daemon <config>

    Arguments:

        config      path to config file


    # GET

    Gets newest or specific block from a chain. 

    $ freechains get <chain>[/<work>] [<block-hash> | <pub-hash>]

    Arguments:

        chain       chain to get block from

        work        exact block work (default: longest work with a block)

        block-hash  exact block hash
        pub-hash    exact publication hash


    # PUBLISH

    Publishes to a chain.

    $ freechains publish <chain>/<work> (<file> | +<string> | -)

    Arguments:

        chain       chain to publish

        work        work to perform

        file        file to publish
        +string     string to publish
        '-'         publish from stdin


    # SUBSCRIBE

    Subscribes to a chain with a list of peers.

    $ freechains subscribe <chain>/<work> {<address>:<port>}

    Arguments:

        chain       chain to subscribe

        work        minimum work required

        address     peer address
        port        peer port


    # CONFIGURE

    Configures freechains.

    $ freechains configure get {<field>}
    $ freechains configure set {<field> (=|+=|-=) <value>}

        field       field to configure
        value       value to set


    # LISTEN

    Listen to a chain.

    $ freechains listen <chain>

    TODO

Options:

    --address=<ip-address>      address to connect/bind (default: `localhost`)
    --port=<tcp-port>           port to connect/bind (default: `8330`)

    --help                      display this help
    --version                   display version information

More Information:

    http://www.freechains.org/

    Please report bugs at <http://github.com/Freechains/freechains>.
]]

local parser = optparse(help)
local arg, opts = parser:parse(_G.arg)
local cmd = arg[1]

local DAEMON = {
    address = opts.address or 'localhost',
    port    = tonumber(opts.port) or 8330,
}

--print('>>>', table.unpack(arg))

if cmd == 'get' then
    ASR(#arg >= 2)
    local key, zeros = string.match(arg[2], '([^/]*)/?([^/]*)')
    zeros = tonumber(zeros)
    local hash = arg[3]

    local ret
    for i=(zeros or 255), (zeros or 0), -1 do
        ret = FC.send(0x0200, {
            chain = {
                key   = key,
                zeros = i,
            },
            block = hash,
            pub   = hash,
        }, DAEMON)
        if ret and ret.prv then
            break
        end
    end
    print(tostring2(ret,'plain'))

elseif cmd == 'publish' then
    ASR(#arg == 3)

    local key, zeros = string.match(arg[2], '([^/]*)/([^/]*)')

    local payload = arg[3]
    if payload == '-' then
        payload = io.stdin:read('*a')
    elseif string.sub(payload,1,1) == '+' then
        payload = string.sub(payload,2)
    else
        payload = ASR(io.open(payload)):read('*a')
    end

    FC.send(0x0300, {
        chain = {
            key   = key,
            zeros = ASR(tonumber(zeros)),
        },
        payload = payload,
    }, DAEMON)

elseif cmd == 'subscribe' then
    ASR(#arg >= 2)

    local key, zeros = string.match(arg[2], '([^/]*)/?([^/]*)')
    zeros = tonumber(zeros) or 0

    local peers = {}
    for i=3, #arg do
        local address, port = string.match(arg[i], '([^:]*):?(.*)')
        port = tonumber(port) or 8330
        peers[#peers+1] = {
            address = address,
            port    = port,
        }
    end

    FC.send(0x0400, {
        chain = {
            key   = key,
            zeros = zeros,
            peers = peers,
        }
    }, DAEMON)

elseif cmd == 'configure' then
    local sub = arg[2]
    ASR(sub=='get' or sub=='set')

    local CFG = FC.send(0x0500, nil, DAEMON)

    if sub == 'get' then
        if #arg == 2 then
            print(tostring2(CFG,'plain'))
        end
    else
        ASR(#arg >= 3)
    end

    local get = {}
    for i=3, #arg do
        local field, op, value = string.match(arg[i], '([^-+=]*)(-?+?=?)(.*)')
        --print(arg[i], field, op, value)

        local T = CFG
        while string.find(field,'.',nil,true) do
            local head
            head, field = string.match(field, '([^.]*)%.(.*)')
            T = T[head]
        end

        if sub == 'get' then
            ASR(op=='' and value=='')
            get[field] = T[field]
        else
            ASR(op=='=' or op=='+=' or op=='-=')
            ASR(value ~= '')

            -- if value evaluates to nil, treat it as a string
            -- handle nil and false as special cases
            if value == 'nil' then
                value = nil
            elseif value == 'false' then
                value = false
            else
                value = ASR(load('return '..value,nil,nil,{}))() or value
            end

            if op == '=' then
                T[field] = value
            elseif op == '+=' then
                T[field][#T[field]+1] = value
            elseif op == '-=' then
                ASR(type(value) == 'number')
                table.remove(T[field], value)
            end
        end
    end

    if sub == 'get' then
        print(tostring2(get,'plain'))
    elseif sub == 'set' then
        FC.send(0x0500, CFG, DAEMON)
    end

elseif cmd == 'daemon' then
    ASR(#arg == 2)
    os.execute('freechains.daemon '..arg[2])

else
    ASR(false)
end
