CHAINS {
    files = '/tmp/fc-02',
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
        key   = 'fs',
        zeros = 0,
        sink  = {
            id = 'fs',
            dir = 'util/fcfs/root-02',
        },
    },
}

SERVER {
    host = { '127.0.0.1', '8332' },
}

CLIENT {
    peers = {
        {
            host =  { '127.0.0.1', '8331' },
        },
    },
}
