server = {
    host = { '127.0.0.1', '8330' },
    backlog = 128,
}

client = {
    peers = {
        { '127.0.0.1', '8331' },
        --{ '127.0.0.1', '8332' },
    },
    time_connection_retry = 5000,
}
