CHAINS {
    files = 'files/',
    {
        key   = '',
        zeros = 0,
    },
    {
        key   = 'chico',
        zeros = 0,
    },
    {
        key   = 'others',
        zeros = 0,
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
