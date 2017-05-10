CHAINS {
    files = 'files/',
    {
        key   = '',
        zeros = 0,
    },
    {
        key   = 'chico',
        zeros = 0,
        sink  = { id='mail' },
    },
    {
        key   = 'others',
        zeros = 0,
        sink  = { id='mail' },
    },
    {
        key   = 'fs',
        zeros = 0,
        sink  = {
            id = 'fs',
            dir = '/tmp/rootdir',
        },
    },
}

SERVER {
    host = { '127.0.0.1', '8331' },
}

CLIENT {
    peers = {
--[[
        {
            host =  { '127.0.0.1', '8332' },
        },
]]
    },
}
