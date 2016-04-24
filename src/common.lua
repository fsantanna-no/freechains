APP = {
    genesis  = __genesis,
    server   = {},  -- server configurations
    client   = {},  -- client configurations
    chains   = {},  -- chains configurations
    messages = {},  -- pending messages to transmit
    blocks = {      -- blocks in memory
        --[hash] = {
        --    hash      = nil,
        --    up_hash   = nil,
        --    tail_hash = nil,
        --    txs       = { tx_hash1, tx_hash2, ... },
        --},
        ...
    },
    txs = {         -- txs in memory
        --[hash] = {
        --    hash      = nil,
        --    timestamp = nil,
        --    bytes     = nil,
        --    payload   = nil,
        --}
    },
}

function chain_parse_id (chain)
    assert(type(chain) == 'table')
    assert(type(chain.key)   == 'string')
    assert(type(chain.zeros) == 'number')
    if chain.key == '' then
        assert(chain.zeros < 256)
    end
    local id = '|'..chain.key..'|'..chain.zeros..'|'
    chain.id = id

    local tx_hash = id          -- TODO: should be hash(id)
    APP.txs[tx_hash] = {
        hash      = tx_hash,
        timestamp = 0,
        bytes     = 0,
        payload   = '',
    }

    -- chain.head
    local block_hash = tx_hash  -- TODO: should be hash of txs merkle tree
    local block_genesis = {
        hash = block_hash,
        txs  = { tx_hash },
    }
    APP.blocks[block_hash] = block_genesis
    chain.head = block_hash

    return id, chain
end

function SERVER (t)
    assert(type(t) == 'table')
    for k,v in pairs(t) do
        APP.server[k] = v
    end
    t = APP.server
    assert(type(t.chains) == 'table')
    for _,chain in ipairs(t.chains) do
        local id = chain_parse_id(chain)
        -- server creates
        --assert(not APP.chains[id])    -- TODO: config override
        APP.chains[id] = chain
    end
end

function CLIENT (t)
    assert(type(t) == 'table')
    for k, v in pairs(t) do
        APP.client[k] = v
    end
    t = APP.client
    assert(type(t.peers) == 'table')

    for _, peer in ipairs(t.peers) do
        assert(type(peer) == 'table')
        assert(type(peer.chains) == 'table')
        for _,chain in ipairs(peer.chains) do
            local id = chain_parse_id(chain, true)
            assert(APP.chains[id])
        end
    end
end

function BLOCKS (t)
    --
end

function MESSAGE (t)
    APP.messages[#APP.messages+1] = t
end

function APP.chain_base_head_len (base)
    local head = base
    local len = 1
    while head.up_hash do
        len = len + 1
        head = APP.blocks[head.up_hash]
    end
    return {
        base = base,
        head = head,
        len  = len
    }
end

function hex_dump(buf)
    local ret = ''
    for byte=1, #buf, 16 do
        local chunk = buf:sub(byte, byte+15)
        ret = ret .. string.format('%08X  ',byte-1)
        chunk:gsub('.',
            function (c)
                ret = ret .. string.format('%02X ',string.byte(c))
            end)
        ret = ret .. string.rep(' ',3*(16-#chunk))
        ret = ret .. ' '..chunk:gsub('%c','.')..'\n'
    end
    return ret
end
