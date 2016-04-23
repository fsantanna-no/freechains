SERVER {
    host = { '127.0.0.1', '8331' },
}

CLIENT {
    peers = {
        {
            host =  { '127.0.0.1', '8332' },
            chains = {
                [''] = {
                    zeros = 0,
                }
            },
        },
    },
}
