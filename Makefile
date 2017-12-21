include Makefile.dirs

main:
	make CEU_SRC=src/main.ceu one
	mv /tmp/main freechains-daemon

install:
	mkdir -p /usr/local/share/lua/5.3/
	cp src/common.lua /usr/local/share/lua/5.3/freechains.lua
	cp src/optparse.lua /usr/local/share/lua/5.3/
	cp src/freechains.cli.lua /usr/local/bin/freechains
	cp src/freechains-liferea.lua /usr/local/bin/freechains-liferea
	cp freechains-daemon /usr/local/bin/

one:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=$(CEU_SRC)                                           \
	    --ceu --ceu-features-lua=true --ceu-features-thread=true               \
	          --ceu-features-trace=true --ceu-features-exception=true          \
	          --ceu-err-uncaught-exception-main=pass --ceu-err-uncaught-exception-lua=pass \
	          --ceu-err-unused=pass --ceu-err-uninitialized=pass               \
	          --ceu-line-directives=true \
	    --env --env-types=$(CEU_DIR)/env/types.h                               \
	          --env-threads=$(CEU_UV_DIR)/env/threads.h                        \
	          --env-main=$(CEU_DIR)/env/main.c                                 \
	    --cc --cc-args="-lm -llua5.3 -luv -lsodium -g"                         \
	         --cc-output=/tmp/$$(basename $(CEU_SRC) .ceu);

pre:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=tst/tst-ae.ceu --pre-output=/tmp/x.ceu

c:
	ceu --cc --cc-input=/tmp/x.c --cc-args="-lm -llua5.3 -luv -lsodium -g"                         \
	         --cc-output=/tmp/x;

tests: tests-get tests-cli tests-nat tests-p2p tests-shared tests-public tests-encrypt tests-seq
	# OK

tests-get:
	-freechains --port=8400 daemon stop 2>/dev/null
	rm -Rf /tmp/freechains/8400/
	cp cfg/config-tests.lua.bak cfg/config-tests.lua
	freechains --port=8400 daemon start cfg/config-tests.lua 2>&1 > /tmp/freechains-tests-get.out &
	sleep 0.5
	freechains --port=8400 configure set deterministic=true
	freechains --port=8400 publish /0 +"Hello World!"
	freechains --port=8400 get /0 > /tmp/freechains-tests-get-1.out
	freechains --port=8400 get /0 994CA2080CA23252F8744A0926B9F49D560F2666C1ABBC96A02FFCA8EABF29FB > /tmp/freechains-tests-get-2.out
	diff /tmp/freechains-tests-get-1.out  tst/out/freechains-tests-get-1.out
	diff /tmp/freechains-tests-get-2.out  tst/out/freechains-tests-get-2.out

tests-cli:
	-killall liferea 2>/dev/null
	-freechains --port=8400 daemon stop 2>/dev/null
	rm -Rf /tmp/freechains/8400/
	cp cfg/config-tests.lua.bak cfg/config-tests.lua
	
	freechains --port=8400 daemon start cfg/config-tests.lua 2>&1 > /tmp/freechains-tests-cli.err &
	sleep 0.5
	freechains --port=8400 configure set deterministic=true
	freechains --port=8400 publish /0 +"NOT SEEN BY LISTEN (seen by liferea)"
	freechains --port=8400 listen 2>/dev/null > /tmp/freechains-tests-cli.out &
	sleep 0.5
	freechains --port=8400 publish /0 +"Hello World!"
	#freechains --port=8400 publish /0 +"to be removed"
	freechains --port=8400 publish /0 +"Hello World! (again)"
	#freechains --port=8400 remove /0 F989AA3AED4CD364E537AACEEDDDCFC9033B4B98113ABFF4AE4373D38D4992D9
	freechains --port=8400 publish /5 +"work = 5"
	freechains-liferea freechains://localhost:8400//?cmd=atom | grep -v "<updated>" > /tmp/freechains-tests-cli.atom
	freechains --port=8400 subscribe new/10
	freechains --port=8400 publish new/0 +"NOT SEEN"
	freechains --port=8400 publish new/10 +"new = 10"
	sleep 0.5
	diff /tmp/freechains-tests-cli.out  tst/out/freechains-tests-cli.out
	diff /tmp/freechains-tests-cli.atom tst/freechains-tests-cli.atom
	diff /tmp/freechains/8400/          tst/freechains-tests-cli/
	freechains --port=8400 subscribe aaa/10
	freechains --port=8400 subscribe bbb/10
	freechains --port=8400 configure get > /dev/null
	freechains --port=8400 daemon stop

tests-shared:
	-freechains --port=8400 daemon stop 2>/dev/null
	-freechains --port=8401 daemon stop 2>/dev/null
	-freechains --port=8402 daemon stop 2>/dev/null
	rm -Rf /tmp/freechains/84*
	
	# Setup configuration files:
	cp cfg/config-tests.lua.bak /tmp/config-8400.lua
	cp cfg/config-tests.lua.bak /tmp/config-8401.lua
	cp cfg/config-tests.lua.bak /tmp/config-8402.lua
	
	# Start three nodes:
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	freechains --port=8401 daemon start /tmp/config-8401.lua &
	freechains --port=8402 daemon start /tmp/config-8402.lua &
	sleep 0.5
	
	# Connect ALL:
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8400}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8400}"
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	
	# Set SHARED for 8400/8401:
	freechains --port=8400 configure set "chains[''].key_shared"="'`freechains --port=8400 crypto create shared --passphrase=senha-secreta`'"
	freechains --port=8401 configure set "chains[''].key_shared"="'`freechains --port=8401 crypto create shared --passphrase=senha-secreta`'"
	
	# Publish to /0
	freechains --port=8400 publish /0 +"from 8400"   # 8402 cannot check
	sleep 0.5
	freechains --port=8402 publish /0 +"from 8402"   # 8400/8401 cannot check
	sleep 0.5
	freechains --port=8401 publish /0 +"from 8401"   # 8402 cannot check
	sleep 3
	
	# Check consensus 1
	grep -q  "from 8400" /tmp/freechains/8400/\|\|0\|.chain
	grep -q  "from 8401" /tmp/freechains/8400/\|\|0\|.chain
	cat -v /tmp/freechains/8400/\|\|0\|.chain | tr '\n' ' ' | grep -qv "from 8402"
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8401
	#
	cat -v /tmp/freechains/8402/\|\|0\|.chain | tr '\n' ' ' | grep -qv "from 8400"
	cat -v /tmp/freechains/8402/\|\|0\|.chain | tr '\n' ' ' | grep -qv "from 8401"
	grep -q  "from 8402" /tmp/freechains/8402/\|\|0\|.chain
	
	# Cleanup
	freechains --port=8400 daemon stop
	freechains --port=8401 daemon stop
	freechains --port=8402 daemon stop

tests-public:
	-freechains --port=8400 daemon stop 2>/dev/null
	-freechains --port=8401 daemon stop 2>/dev/null
	-freechains --port=8402 daemon stop 2>/dev/null
	rm -Rf /tmp/freechains/84*
	
	# Setup configuration files:
	cp cfg/config-tests.lua.bak /tmp/config-8400.lua
	cp cfg/config-tests.lua.bak /tmp/config-8401.lua
	cp cfg/config-tests.lua.bak /tmp/config-8402.lua
	
	# Start three nodes:
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	freechains --port=8401 daemon start /tmp/config-8401.lua &
	freechains --port=8402 daemon start /tmp/config-8402.lua &
	sleep 0.5
	
	# Connect ALL:
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8400}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8400}"
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	
	# Set PUBLIC for 8400/8401:
	freechains --port=8400 configure set "chains[''].key_public"="'`freechains --port=8400 crypto create public --passphrase=senha-secreta`'"
	freechains --port=8401 configure set "chains[''].key_public"="'`freechains --port=8401 crypto create public --passphrase=senha-secreta`'"
	freechains --port=8402 configure set "chains[''].key_public"="'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'"
	sleep 1
	
	# Wrong key
	sleep 1
	freechains --port=8400 publish --sign='EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE' /0 +"from 8400"
	sleep 1
	! ls /tmp/freechains/8400/\|\|0\|.chain
	
	# Publish to /0
	freechains --port=8400 publish --sign="`freechains --port=8400 crypto create private --passphrase=senha-secreta`" /0 +"from 8400"
	freechains --port=8401 publish --sign="`freechains --port=8401 crypto create private --passphrase=senha-secreta`" /0 +"from 8401"
	sleep 1
	
	# Check consensus 1
	grep -q  "from 8400" /tmp/freechains/8400/\|\|0\|.chain
	grep -q  "from 8401" /tmp/freechains/8400/\|\|0\|.chain
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8401
	#
	! ls /tmp/freechains/8402/\|\|0\|.chain
	
	# Cleanup
	freechains --port=8400 daemon stop
	freechains --port=8401 daemon stop
	freechains --port=8402 daemon stop

tests-encrypt: tests-encrypt-shared #TODO-tests-encrypt-public
	-freechains --port=8400 daemon stop 2>/dev/null
	cp cfg/config-tests.lua.bak /tmp/config-8400.lua
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	lua5.3 tst/tst-crypto.lua
	#
tests-encrypt-shared:
	-freechains --port=8400 daemon stop 2>/dev/null
	-freechains --port=8401 daemon stop 2>/dev/null
	rm -Rf /tmp/freechains/84*
	
	# Setup configuration files:
	cp cfg/config-tests.lua.bak /tmp/config-8400.lua
	cp cfg/config-tests.lua.bak /tmp/config-8401.lua
	
	# Start two nodes:
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	freechains --port=8401 daemon start /tmp/config-8401.lua &
	sleep 0.5
	
	# Connect ALL:
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8400}"
	
	# Set SHARED for 8400/8401:
	freechains --port=8400 configure set "chains[''].key_shared"="'`freechains --port=8400 crypto create shared --passphrase=senha-secreta`'"
	freechains --port=8401 configure set "chains[''].key_shared"="'`freechains --port=8401 crypto create shared --passphrase=senha-secreta`'"
	
	# Publish to /0 with --encrypt
	echo -n "from 8400" > /tmp/freechains/8400/msg.1
	freechains --port=8400 crypto encrypt shared EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE /tmp/freechains/8400/msg.1 > /tmp/freechains/8400/msg.2
	freechains --port=8400 publish /0 /tmp/freechains/8400/msg.2
	sleep 2
	lua5.3 -e "io.stdout:write( (`freechains --port=8401 get /0`)[1].pub.payload )" > /tmp/freechains/8400/msg.3
	freechains --port=8400 crypto decrypt shared EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE /tmp/freechains/8400/msg.3 > /tmp/freechains/8400/msg.4
	diff /tmp/freechains/8400/msg.[23]
	diff /tmp/freechains/8400/msg.[14]
	grep -q "from 8400" /tmp/freechains/8400/msg.1
	
	# Cleanup
	freechains --port=8400 daemon stop
	freechains --port=8401 daemon stop
TODO-tests-encrypt-public:
	-freechains --port=8400 daemon stop 2>/dev/null
	-freechains --port=8401 daemon stop 2>/dev/null
	rm -Rf /tmp/freechains/84*
	
	# Setup configuration files:
	cp cfg/config-tests.lua.bak /tmp/config-8400.lua
	cp cfg/config-tests.lua.bak /tmp/config-8401.lua
	
	# Start two nodes:
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	freechains --port=8401 daemon start /tmp/config-8401.lua &
	sleep 0.5
	
	# Connect ALL:
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8400}"
	
	# Set PUBLIC for 8400/8401:
	freechains --port=8400 configure set "chains[''].key_public"="'89BC9897BF4BD5E5491B0604A9087C6FDF6F5A3DAB30E5ABA4EF9E1D90F63C46'"
	freechains --port=8401 configure set "chains[''].key_public"="'89BC9897BF4BD5E5491B0604A9087C6FDF6F5A3DAB30E5ABA4EF9E1D90F63C46'"
	
	# Publish to /0 with --encrypt
	freechains --port=8400 publish --sign='24A14567A3FD04F201EA6E16F2702C2D7035704C3E230A73B3C767B9149DB45F89BC9897BF4BD5E5491B0604A9087C6FDF6F5A3DAB30E5ABA4EF9E1D90F63C46' --encrypt /0 +"from 8400"
	sleep 2
	freechains --port=8401 get /0 --decrypt='24A14567A3FD04F201EA6E16F2702C2D7035704C3E230A73B3C767B9149DB45F89BC9897BF4BD5E5491B0604A9087C6FDF6F5A3DAB30E5ABA4EF9E1D90F63C46' | grep "from 8400"
	
	# Cleanup
	freechains --port=8400 daemon stop
	freechains --port=8401 daemon stop

tests-nat:
	rm -Rf /tmp/freechains/840[0-1]/
	cp cfg/config-tests.lua.bak /tmp/config-8400.lua
	cp cfg/config-tests.lua.bak /tmp/config-8401.lua
	freechains --port=8401 daemon start /tmp/config-8401.lua &
	sleep 0.5
	freechains --port=8401 publish /0 +"Hello World (from 8401)"
	sleep 0.5
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	sleep 0.5
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	sleep 1
	grep -q "from 8401" /tmp/freechains/8400/\|\|0\|.chain
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8401

tests-p2p:
	-freechains --port=8400 daemon stop 2>/dev/null
	-freechains --port=8401 daemon stop 2>/dev/null
	-freechains --port=8402 daemon stop 2>/dev/null
	-freechains --port=8403 daemon stop 2>/dev/null
	-freechains --port=8404 daemon stop 2>/dev/null
	rm -Rf /tmp/freechains/84*
	
	# Setup configuration files:
	cp cfg/config-tests.lua.bak /tmp/config-8400.lua
	cp cfg/config-tests.lua.bak /tmp/config-8401.lua
	cp cfg/config-tests.lua.bak /tmp/config-8402.lua
	
	# Start three nodes:
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	freechains --port=8401 daemon start /tmp/config-8401.lua &
	freechains --port=8402 daemon start /tmp/config-8402.lua &
	sleep 0.5
	
	# Connect 8400 <-> 8401 <-> 8402:
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8400}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	
	# Publish to /0
	freechains --port=8402 publish /0 +"Hello World (from 8402)"  # 8402->8401->8400
	sleep 2
	freechains --port=8400 publish /0 +"Hello World (from 8400)"  # 8400->8401->8402
	sleep 2
	
	# Check consensus 1
	grep -q "from 8402" /tmp/freechains/8400/\|\|0\|.chain
	grep -q "from 8400" /tmp/freechains/8400/\|\|0\|.chain
	#grep -q "from 8402.*from 8400" /tmp/freechains/8400/\|\|0\|.chain
	cat -v /tmp/freechains/8400/\|\|0\|.chain | tr '\n' ' ' | grep -q "from 8402.*from 8400"
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8401
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8402
	
	###
	
	# Start fourth node, 8400 <-> 8401 <-> 8402 <-> 8403:
	cp cfg/config-tests.lua.bak /tmp/config-8403.lua
	freechains --port=8403 daemon start /tmp/config-8403.lua &
	sleep 0.5
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8403}"
	freechains --port=8403 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	sleep 0.5
	# (it should receive both messages)
	
	# Check consensus 2
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8403
	
	###
	
	# Start fifth node alone
	cp cfg/config-tests.lua.bak /tmp/config-8403.lua
	freechains --port=8404 daemon start /tmp/config-8403.lua &
	sleep 0.5
	
	# Publish to reach longest chain
	freechains --port=8404 publish /0 +"Hello World (from 8404 1/3)"
	freechains --port=8404 publish /0 +"Hello World (from 8404 2/3)"
	freechains --port=8404 publish /0 +"Hello World (from 8404 3/3)"
	sleep 0.5
	
	# Connect with 1/2
	#             /-8404-\
	# 8400 <-> 8401 <-> 8402 <-> 8403:
	freechains --port=8404 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8404}"
	freechains --port=8404 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8404}"
	sleep 4
	
	# Check consensus 3
	# (8404 wins, so his messages should appear first)
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8401
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8402
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8403
	diff -I '["seq"]' /tmp/freechains/8400 /tmp/freechains/8404
	#cat -v /tmp/freechains/8400/\|\|0\|.chain | tr '\n' ' ' | grep -q "from 8404.*from 8402.*from 8400"
	cat -v /tmp/freechains/8400/\|\|0\|.chain | tr '\n' ' ' | grep -q "1/3.*2/3.*3/3"
	
	###
	
	# TODO: stop node, publish, restart
	# TODO: big messages
	
	###
	
	# Cleanup
	freechains --port=8400 daemon stop
	freechains --port=8401 daemon stop
	freechains --port=8402 daemon stop
	freechains --port=8403 daemon stop
	freechains --port=8404 daemon stop

tests-seq:
	-freechains --port=8400 daemon stop 2>/dev/null
	rm -Rf /tmp/freechains/8400
	cp cfg/config-tests.lua.bak /tmp/config-8400.lua
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	sleep 0.5
	freechains --port=8400 get /0 | grep -q "seq.*1"
	freechains --port=8400 publish /0 +"Hello World!"
	sleep 0.5
	freechains --port=8400 get /0 | grep -q "seq.*2"
	freechains --port=8400 daemon stop

tmp:
	#for i in tst/tst-29.ceu tst/tst-3[0-6].ceu ; do
	#for i in tst/tst-[a-b]*.ceu tst/tst-[0-3]*.ceu ; do
	for i in tst/tst-a*.ceu ; do \
	    echo;                                            \
	    echo "#####################################";    \
	    echo File: "$$i";                                \
	    echo "#####################################";    \
	    make CEU_SRC=$$i one && /tmp/$$(basename $$i .ceu) || exit 1; \
	done

tests-full:
	for i in tst/tst-[0-2]*.ceu tst/tst-[a-c]*.ceu tst/tst-3[0-3].ceu ; do \
	    echo;                                            \
	    echo "#####################################";    \
	    echo File: "$$i";                                \
	    echo "#####################################";    \
	    make CEU_SRC=$$i one && /tmp/$$(basename $$i .ceu) || exit 1; \
	done

tests-full-run:
	for i in tst/tst-[0-2]*.ceu tst/tst-[a-c]*.ceu tst/tst-3[0-3].ceu ; do \
	    echo;                                            \
	    echo "#####################################";    \
	    echo File: "$$i";                                \
	    echo "#####################################";    \
	    /tmp/$$(basename $$i .ceu) || exit 1;            \
	done
