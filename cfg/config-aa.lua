SERVER {
    host = { '127.0.0.1', '8341' },
}

CLIENT {
    peers = {
        {
            host =  { '127.0.0.1', '8342' },
            chains = {
                [''] = {
                    zeros = 0,
                }
            },
        },
    },
}
