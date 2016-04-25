SERVER {
    host = { '127.0.0.1', '8342' },
}

CLIENT {
    peers = {
        {
            host = { '127.0.0.1', '8343' },
            chains = APP.server.chains,
        },
    },
}

