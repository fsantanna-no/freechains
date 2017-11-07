Freechains: Let's redistribute de Internet!

Freechains is...

# Install

## Software Packages

```
$ sudo apt-get install git gcc libuv1-dev lua5.3 lua5.3-dev lua-lpeg  # Céu
$ sudo apt-get install libsodium-dev                                  # Freechains
$ sudo apt-get install liferea lua-socket zenity pandoc               # GUI
```

## Source Repositories

```
$ mkdir ceu
$ cd ceu/
$ git clone https://github.com/fsantanna/ceu
$ git clone https://github.com/fsantanna/ceu-libuv
$ git clone https://github.com/Freechains/freechains

$ cd ceu/
$ make
$ sudo make install
$ cd ..

$ vi ceu-libuv/Makefile                 # set directories by hand
$ vi freechains/Makefile                # set directories by hand

$ cd freechains/
$ make
$ sudo make install     # /usr/local/bin/{freechains,freechains.daemon,freechains}
$ make tests
$ make tests-full       # (optional, takes a lot of time)
```

# Use

## Command Line

- Start the `freechains` daemon:

```
$ freechains start daemon cfg/config.lua    # blocks the terminal
```

- Listen for new publications:

```
$ freechains listen                         # blocks the terminal
```

- Publish some content:

```
$ freechains publish /0 +"Hello World"      # publishes on the general chain (`/`) with 0 of work
```

You should now see output from `freechains listen`.

- Subscribe to a chain:

```
$ freechains subscribe new/5                # subscribes to "new" and only accept publication with at least 5 of work
```

- Publish some content to `new`:

```
$ freechains publish new/0 +"Hello World (little work)"
$ freechains publish new/5 +"Hello World (enough work)"
```

Only the second publication should appear on `freechains listen`

- Communicate with other peers:

```
# Setup configuration files:
$ cp cfg/config.lua.bak /tmp/config-8331.lua
$ cp cfg/config.lua.bak /tmp/config-8332.lua

# Start two new nodes:
$ freechains --port=8331 daemon /tmp/config-8331.lua &
$ freechains --port=8332 daemon /tmp/config-8332.lua &

# Connect, in both directions, 8330 with 8331 and 8331 with 8332:
$ freechains --port=8330 configure set "chains[''].peers"+="{address='127.0.0.1',port=8331}"
$ freechains --port=8331 configure set "chains[''].peers"+="{address='127.0.0.1',port=8330}"
$ freechains --port=8331 configure set "chains[''].peers"+="{address='127.0.0.1',port=8332}"
$ freechains --port=8332 configure set "chains[''].peers"+="{address='127.0.0.1',port=8331}"

$ freechains --port=8332 publish /0 +"Hello World (from 8332)"
```

This creates a peer-to-peer mesh with the form `8330 <-> 8331 <-> 8332`,
allowing nodes `8330` and `8332` to communicate even though they are not
directly connected.

## Liferea GUI

Liferea is a RSS reader adapted to freechains.

### Setup

- Delete default feeds:

```
Example Feeds -> Delete
```

- Intercept links in posts:

```
Tools -> Preferences -> Browser -> Browser -> Manual -> Manual ->
    freechains-liferea %s
```

In some versions, clicking a link still opens the browser.
Alternativelly, use the command line:

```
$ gsettings set net.sf.liferea browser 'freechains-liferea %s'
```

- Add the `general` chain:

```
+ New Subscription -> Advanced -> Command -> Source
    freechains-liferea freechains://localhost:8330//?cmd=atom
```

- Add the `new` chain:

```
+ New Subscription -> Advanced -> Command -> Source
    freechains-liferea freechains://localhost:8330/new/?cmd=atom
```

You should see the posts published from the command line above.

### GUI

You can operate the chains from the Liferea GUI itself.

The first post of chain is a `Menu` with some options:

- *New Chain*:           creates a new chain (only available in the `general` chain)
- *Change Minimum Work*: only receive posts with at least the provided work
- *Publish*:             publish to the chain

Each post also provides some options:

- *Republish Contents*:     republishes to the same or another chain, possibly employing more work
- *Inappropriate Contents*: remove the publication from the chain
