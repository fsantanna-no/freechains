SERVER {
    host = { '127.0.0.1', '8333' },
}

CLIENT {
    peers = {
        {
            host = { '127.0.0.1', '8343' },
            chains = APP.server.chains,
        },
    },
}

