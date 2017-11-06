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

tests-cli:
	-killall liferea
	-killall freechains-daemon
	rm -Rf /tmp/freechains/8400/
	cp cfg/config-tests.lua.bak cfg/config-tests.lua
	freechains --port=8400 daemon cfg/config-tests.lua 2>&1 > /tmp/freechains-tests-cli.err &
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

tests:
	for i in tst/tst-[0-2]*.ceu tst/tst-[a-b]*.ceu tst/tst-3[0-3].ceu ; do \
		echo;                                            \
		echo "#####################################";    \
		echo File: "$$i";                                \
		echo "#####################################";    \
		make CEU_SRC=$$i one && /tmp/$$(basename $$i .ceu) || exit 1; \
	done

tests-run:
	for i in tst/tst-[0-2]*.ceu tst/tst-[a-b]*.ceu tst/tst-3[0-3].ceu ; do \
		echo;                                            \
		echo "#####################################";    \
		echo File: "$$i";                                \
		echo "#####################################";    \
		/tmp/$$(basename $$i .ceu) || exit 1;            \
	done
