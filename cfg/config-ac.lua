SERVER {
    host = { '127.0.0.1', '8343' },
}

CLIENT {
    peers = {
        {
            host = { '127.0.0.1', '8333' },
            chains = APP.server.chains,
        },
    },
}
