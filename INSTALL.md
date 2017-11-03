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

$ vi ceu-libuv/Makefile               # set directories by hand
$ vi freechains/Makefile              # set directories by hand
$ vi freechains/util/liferea/cmd.lua  # set directories by hand

$ cd freechains/
$ make
$ make tst        # compiles and run tests, takes a lot of time
```

## Freechains

- Testing mode:

```
$ make tst-cmds-set  # restart freechains from scratch every time
$ make tst-cmds-go   # in another terminal, publish some contents
```

- Persistent mode:

```
$ vi /<freechains-repo>/cfg/<some-cfg>.lua
$ ./freechains /<freechains-repo>/cfg/<some-cfg>.lua
```

## GUI

Liferea is a RSS reader adapted to freechains.

- Delete default feeds:

```
Example Feed -> Delete
```

- Intercept links in posts:

```
Tools -> Preferences -> Browser -> Browser -> Manual -> Manual ->
    /<freechains-repo>/util/liferea/cmd.lua %s
```

In some versions, clicking a link still opens the browser.
Alternativelly, use the command line:

```
$ gsettings set net.sf.liferea browser '/<freechains-repo>/util/liferea/cmd.lua %s'
```

- Add the root chain:

```
+ New Subscription -> Advanced -> Command -> Source
    /<freechains-repo>/util/liferea/cmd.lua freechains://?cmd=atom\&cfg=/<freechains-repo>/cfg/<config.lua>
```

<!--
In testing mode, `<port>` is `8400`.
-->
