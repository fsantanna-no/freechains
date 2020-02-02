# Freechains Protocol

```
0       1       2       3       4..
'P'    'S'    [message type]    ...
```

## Message Type:

- `common.ceu:75`
- `server.ceu:35`

```
enum {
    MESSAGE00 = 0x0000,     // STOP freechains
    MESSAGE10 = 0x0100,     // broadcast chain
    MESSAGE20 = 0x0200,     // GET a chain state
    MESSAGE30 = 0x0300,     // PUBLISH to a chain
    MESSAGE40 = 0x0400,     // SUBSCRIBE to a chain
    MESSAGE50 = 0x0500,     // CONFIGURE freechains
    MESSAGE60 = 0x0600,     // LISTEN for new nodes
    MESSAGE70 = 0x0700,     // CRYPTO management
};
```

### Message `10` (broadcast chain)

```
0       1       2       3       4...
'P'    'S'      1       0       ...
```

- `client.ceu:68`
    - `[74]` gets all chain peers (as servers)
    - `[95]` iterates over them
        - `[96]` checks if peer is interested in our zeros
        - `[104]` spawns chain/peer handler
            - `[24]` peer handler
            - `[48]` connect to server ip/port
            - `[58]` `Send_10_Header`
            - `[61]` `Send_10_Nodes`
            - `[64]` `Recv_10_Nodes`
    - `[115]` awaits all peers to finalize

- `server.ceu:52`
    - `[55]` `Recv_10_Header`
    - `[59]` `Recv_10_Nodes`
    - `[62]` `Send_10_Nodes`

- Header
    - `Send_10_Header`: `message_10:383`
    - `Recv_10_Header`: `message_10:4`
        - `[37]` verifies if subscribed

```
0       1       2       3       4       5       6       7       8
'P'    'S'      1       0       key_len [------  key_str  ------]

8       9       10      11      12      13      14      15      16
16      17      18      19      20      21      22      23      24
24      25      26      27      28      29      30      31      32
[--------------------------  key_str  --------------------------]

32
zeros
```

- Nodes
    - `Send_10_Nodes`: `message_10:412`
    - `Recv_10_Nodes`: `message_10:172`
    - 

### Message `30` (publish to chain)

```
0       1       2       3       4       5       6       7       8
'P'    'S'      3       0       [-------  message length  ------]

8...
[--  lua table  --]
```

- `freechains.cli.lua:222`
- `server.ceu:69`
- `message_30.ceu`

- Lua Table:
    - `message_30.ceu34:`
```
pub = {
    chain     = ...,        -- chain to publish
    timestamp = now,        -- time now
    nonce     = ...,        -- starting nonce
    payload   = ...,        -- message contents
    sign      = ...,        -- public signature
    encrypt   = ...,        -- none, shared, public
}
```
- `client_10.ceu`
    - `[402]` verifies if server follows chain key/zeros
    - `[403]` verifies chain crypto (none, public, shared)
    - `[419]` creates new publication
        - `[137]` concatenates timestamp+nonce+key+payload
        - `[173]` iterates over timestamp/nonce
        - `[182]` finds 256-bit hash with expected zeros
```
0       1       2       3       4       5       6       7       8
[-------------------------  timestamp  -------------------------]

8       9       10      11      12      13      14      15      16
[---------------------------  nonce  ---------------------------]

16      17      18      19      20      21      22      23      24
24      25      26      27      28      29      30      31      32
32      33      34      35      36      37      38      39      40
40      41      42      43      44      45      46      47      48
[----------------------------  hash  ---------------------------]

48...
[-- payload --]
```
    - `[450]` creates new node in the chain with the publication
```
node = {
    chain     = ...,        -- chain to publish
    timestamp = now,        -- time now
    nonce     = ...,        -- starting nonce
    pub       = pub,        -- publication just created
    sign      = ...,        -- public signature
    encrypt   = ...,        -- none, shared, public
    [1]       = ...,        -- backlinks
    ...       = ...,
    [N]       = ...,
}
```

        - `[459]` backlink to head nodes
            - `[common.lua:39]` sorted by backlink hash
```
h1  <---\
... <----| node
hN  <---/
```
        - `[294]` concatenates timestamp+nonce+pub_hash+backs_hashes
        - `[330]` iterates over timestamp/nonce
        - `[339]` finds 256-bit hash with expected zeros (use shared key if available)
```
0       1       2       3       4       5       6       7       8
[-------------------------  timestamp  -------------------------]

8       9       10      11      12      13      14      15      16
[---------------------------  nonce  ---------------------------]

16      17      18      19      20      21      22      23      24
24      25      26      27      28      29      30      31      32
32      33      34      35      36      37      38      39      40
40      41      42      43      44      45      46      47      48
[--------------------------  pub_hash  -------------------------]

48      ..      ..      ..      ..      ..      ..      ..      56
56      ..      ..      ..      ..      ..      ..      ..      64
64      ..      ..      ..      ..      ..      ..      ..      72
72      ..      ..      ..      ..      ..      ..      ..      80
[-------------------------  back1_hash  ------------------------]

...

80      ..      ..      ..      ..      ..      ..      ..      88
88      ..      ..      ..      ..      ..      ..      ..      96
96      ..      ..      ..      ..      ..      ..      ..      104
104     ..      ..      ..      ..      ..      ..      ..      112
[-------------------------  backN_hash  ------------------------]


8       9       10      11      12      13      14      15      16
[----------  pub_hash  ---------|-----------  back-1  ----------]

16...
[-- backs-N --]
```
        - `[359]` TODO: `FC.node`
            - `[common.lua:16]` TODO: seq? height?
        - `[362]` TODO: `node.sign`
    - `[465]` TODO: `Node_Check`
    - `[472]` set new node as one of chain heads
    - `[478]` `emit ok_node` / `FC.write`
    - `[481]` chain broadcast is now pending
    - `[544]` handle next pending chain (see `Message 10`)
