#!/usr/bin/env lua5.3

local FC       = require 'freechains'
local optparse = require 'optparse'

local function ASR (cnd, msg)
    msg = msg or 'malformed command'
    if not cnd then
        io.stderr:write('ERROR: '..msg..'\n')
        os.exit(1)
    end
    return cnd
end

local help = [=[
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


    # REMOVE

    Removes a block from a chain.

    $ freechains remove <chain>/<work> <block-hash>

    Arguments:

        chain       chain to remove the block

        work        chain work with the block

        block-hash  hash of the block to remove


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

    Listen for new blocks.

    $ freechains listen [<chain>[/<work>]]

    Arguments:

        chain       chain to listen for blocks (default: all chains)

        work        minimum block work (default: `0`)

Options:

    --address=<ip-address>      address to connect/bind (default: `localhost`)
    --port=<tcp-port>           port to connect/bind (default: `8330`)

    --help                      display this help
    --version                   display version information

More Information:

    http://www.freechains.org/

    Please report bugs at <http://github.com/Freechains/freechains>.
]=]

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
    print(FC.tostring(ret,'plain'))

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

elseif cmd == 'remove' then
    ASR(#arg == 3)

    local key, zeros = string.match(arg[2], '([^/]*)/([^/]*)')

    FC.send(0x0300, {
        chain = {
            key   = key,
            zeros = ASR(tonumber(zeros)),
        },
        removal = arg[3],
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

    CFG = FC.send(0x0500, nil, DAEMON)

    if sub=='get' and #arg==2 then
        print(FC.tostring(CFG,'plain'))
    else
        ASR(#arg == 3)

        local field, op, value = string.match(arg[3], '([^-+=]*)(-?+?=?)(.*)')
        str = 'CFG.'..field

        if sub == 'get' then
            print(FC.tostring( assert(load('return '..str))() , 'plain' ))
        else
            ASR(op=='=' or op=='+=' or op=='-=')
            ASR(value ~= '')

            -- if value evaluates to nil, treat it as a string
            -- handle nil and false as special cases
            if value~='nil' and value~='false' then
                value = value..' or "'..value..'"'
            end

            if op == '=' then
                assert(load(str..' = '..value))()
            elseif op == '+=' then
                assert(load(str..'[#'..str..'+1] = '..value))()
            elseif op == '-=' then
                assert(load('table.remove('..str..', assert(tonumber('..value..')))'))()
            end

            FC.send(0x0500, CFG, DAEMON)
        end
    end

elseif cmd == 'listen' then
    ASR(#arg <= 2)
    local chain
    if #arg == 2 then
        local key, zeros = string.match(arg[2], '([^/]*)/?([^/]*)')
        zeros = tonumber(zeros)
        chain = {
            key   = key,
            zeros = zeros,
        }
    else
        chain = nil
    end

    FC.send(0x0600, {
        chain = chain,
    }, DAEMON)

elseif cmd == 'daemon' then
    ASR(#arg == 2)
    os.execute('freechains-daemon '..arg[2]..' '..DAEMON.address..' '..DAEMON.port)

else
    ASR(false)
end
