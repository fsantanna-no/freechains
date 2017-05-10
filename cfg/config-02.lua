CHAINS {
    files = 'files-01/',
    {
        key   = 'fs',
        zeros = 0,
        sink  = {
            id = 'fs',
            dir = 'util/fcfs/root-01',
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
