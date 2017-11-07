CEU_DIR    = $(error set absolute path to "<ceu>" repository)
CEU_UV_DIR = $(error set absolute path to "<ceu-libuv>" repository)

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

tests: tests-cli tests-p2p
	# OK

tests-cli:
	-killall liferea
	-killall freechains-daemon
	rm -Rf /tmp/freechains/8400/
	cp cfg/config-tests.lua.bak cfg/config-tests.lua
	freechains --port=8400 daemon start cfg/config-tests.lua 2>&1 > /tmp/freechains-tests-cli.err &
	sleep 0.5
	freechains --port=8400 configure set deterministic=true
	freechains --port=8400 publish /0 +"NOT SEEN BY LISTEN (seen by liferea)"
	freechains --port=8400 listen > /tmp/freechains-tests-cli.out &
	sleep 0.5
	freechains --port=8400 publish /0 +"Hello World!"
	freechains --port=8400 publish /0 +"to be removed"
	freechains --port=8400 publish /0 +"Hello World! (again)"
	freechains --port=8400 remove /0 F989AA3AED4CD364E537AACEEDDDCFC9033B4B98113ABFF4AE4373D38D4992D9
	freechains --port=8400 publish /5 +"work = 5"
	freechains-liferea freechains://localhost:8400//?cmd=atom | grep -v "<updated>" > /tmp/freechains-tests-cli.atom
	freechains --port=8400 subscribe new/10
	freechains --port=8400 publish new/0 +"NOT SEEN"
	freechains --port=8400 publish new/10 +"new = 10"
	sleep 0.5
	diff /tmp/freechains-tests-cli.out  tst/freechains-tests-cli.out
	diff /tmp/freechains-tests-cli.atom tst/freechains-tests-cli.atom
	diff /tmp/freechains/8400/          tst/freechains-tests-cli/
	freechains --port=8400 daemon stop

tests-p2p:
	rm -Rf /tmp/freechains/84*
	
	# Setup configuration files:
	cp cfg/config.lua.bak /tmp/config-8400.lua
	cp cfg/config.lua.bak /tmp/config-8401.lua
	cp cfg/config.lua.bak /tmp/config-8402.lua
	
	# Start three nodes:
	freechains --port=8400 daemon start /tmp/config-8400.lua &
	freechains --port=8401 daemon start /tmp/config-8401.lua &
	freechains --port=8402 daemon start /tmp/config-8402.lua &
	sleep 0.1
	
	# Connect 8400 <-> 8401 <-> 8402:
	freechains --port=8400 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8400}"
	freechains --port=8401 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8401}"
	
	# Publish to /0
	freechains --port=8402 publish /0 +"Hello World (from 8402)"  # 8402->8401->8400
	sleep 0.5
	freechains --port=8400 publish /0 +"Hello World (from 8400)"  # 8400->8401->8402
	sleep 0.5
	
	# Check consensus 1
	grep -q "from 8402" /tmp/freechains/8400/\|\|0\|.chain
	grep -q "from 8400" /tmp/freechains/8400/\|\|0\|.chain
	#grep -q "from 8402.*from 8400" /tmp/freechains/8400/\|\|0\|.chain
	cat -v /tmp/freechains/8400/\|\|0\|.chain | tr '\n' ' ' | grep -q "from 8402.*from 8400"
	diff /tmp/freechains/8400 /tmp/freechains/8401
	diff /tmp/freechains/8400 /tmp/freechains/8402
	
	###
	
	# Start fourth node, 8400 <-> 8401 <-> 8402 <-> 8403:
	cp cfg/config.lua.bak /tmp/config-8403.lua
	freechains --port=8403 daemon start /tmp/config-8403.lua &
	sleep 0.1
	freechains --port=8402 configure set "chains[''].peers"+="{address='127.0.0.1',port=8403}"
	freechains --port=8403 configure set "chains[''].peers"+="{address='127.0.0.1',port=8402}"
	sleep 0.5
	# (it should receive both messages)
	
	# Check consensus 2
	diff /tmp/freechains/8400 /tmp/freechains/8403
	
	###
	
	# Start fifth node alone
	# Publish to reach longest chain
	# Connect with 1/2
	# Check consensus
	# Check first messages appear last
	
	# Cleanup
	freechains --port=8400 daemon stop
	freechains --port=8401 daemon stop
	freechains --port=8402 daemon stop
	freechains --port=8403 daemon stop

tests-full:
	for i in tst/tst-[0-2]*.ceu tst/tst-[a-b]*.ceu tst/tst-3[0-3].ceu ; do \
		echo;                                            \
		echo "#####################################";    \
		echo File: "$$i";                                \
		echo "#####################################";    \
		make CEU_SRC=$$i one && /tmp/$$(basename $$i .ceu) || exit 1; \
	done

tests-full-run:
	for i in tst/tst-[0-2]*.ceu tst/tst-[a-b]*.ceu tst/tst-3[0-3].ceu ; do \
		echo;                                            \
		echo "#####################################";    \
		echo File: "$$i";                                \
		echo "#####################################";    \
		/tmp/$$(basename $$i .ceu) || exit 1;            \
	done
