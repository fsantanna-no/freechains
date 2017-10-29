# Chain File Format

```
// HEADER + CHAIN
 0    1   2   3   4   5#LEN (max=255)
'P'  'S'  1   0  LEN       ID

// TODO: genesis hash

// BLOCKS
   0#32          32#8           40#8
BLOCK_HASH  BLOCK_TIMESTAMP  BLOCK_NONCE
  48#32          80#8           88#8       96#4    100#PUB_LEN  100+PUB_LEN#4
 PUB_HASH    PUB_TIMESTAMP    PUB_NONCE   PAY_LEN  PUB_PAYLOAD     PAY_LEN
...
```
