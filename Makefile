CEU_DIR    = $(error set absolute path to "<ceu>" repository)
CEU_UV_DIR = $(error set absolute path to "<ceu-libuv>" repository)
CEU_FC_DIR = $(error set absolute path to "<ceu-libuv>" repository)

main:
	make CEU_SRC=src/main.ceu one
	mv /tmp/main freechains-daemon

install:
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

tst-cmds-set:
	rm -Rf /tmp/freechains/8400/
	cp cfg/config-8400.lua.bak cfg/config-8400.lua
	./freechains $(CEU_FC_DIR)/cfg/config-8400.lua

tst-cmds-go:
	echo 38             > /tmp/freechains/8400/fifo.in
	cat tst/atom.lua    > /tmp/freechains/8400/fifo.in
	echo 185            > /tmp/freechains/8400/fifo.in
	cat tst/pub.lua     > /tmp/freechains/8400/fifo.in
	echo 242            > /tmp/freechains/8400/fifo.in
	cat tst/pub-sub.lua > /tmp/freechains/8400/fifo.in
	echo 182            > /tmp/freechains/8400/fifo.in
	cat tst/pub-add.lua > /tmp/freechains/8400/fifo.in
	echo 177            > /tmp/freechains/8400/fifo.in
	cat tst/pub-5.lua   > /tmp/freechains/8400/fifo.in
	echo 187            > /tmp/freechains/8400/fifo.in
	cat tst/sub.lua     > /tmp/freechains/8400/fifo.in
	#echo 297            > /tmp/freechains/8400/fifo.in
	#cat tst/pub-rem.lua > /tmp/freechains/8400/fifo.in
	echo 189            > /tmp/freechains/8400/fifo.in
	cat tst/pub-new.lua > /tmp/freechains/8400/fifo.in

tst-cmds-go-net:
	#/bin/echo -n PS                    >  /tmp/msg.txt
	#/bin/echo -n -e '\xF0\x00'         >> /tmp/msg.txt
	#/bin/echo -n -e '\x00\x00\x00\xB9' >> /tmp/msg.txt
	#cat tst/pub.lua                    >> /tmp/msg.txt
	#cat /tmp/msg.txt | nc localhost 8400
	#
	#/bin/echo -n PS                    >  /tmp/msg.txt
	#/bin/echo -n -e '\xF0\x00'         >> /tmp/msg.txt
	#/bin/echo -n -e '\x00\x00\x00\xF5' >> /tmp/msg.txt
	#cat tst/pub-sub.lua                >> /tmp/msg.txt
	#cat /tmp/msg.txt | nc localhost 8400
	#
	#/bin/echo -n PS                    >  /tmp/msg.txt
	#/bin/echo -n -e '\xF0\x00'         >> /tmp/msg.txt
	#/bin/echo -n -e '\x00\x00\x00\xB6' >> /tmp/msg.txt
	#cat tst/pub-add.lua                >> /tmp/msg.txt
	#cat /tmp/msg.txt | nc localhost 8400
	#
	#/bin/echo -n PS                    >  /tmp/msg.txt
	#/bin/echo -n -e '\xF0\x00'         >> /tmp/msg.txt
	#/bin/echo -n -e '\x00\x00\x00\xB1' >> /tmp/msg.txt
	#cat tst/pub-5.lua                  >> /tmp/msg.txt
	#cat /tmp/msg.txt | nc localhost 8400
	#
	#/bin/echo -n PS                    >  /tmp/msg.txt
	#/bin/echo -n -e '\xF0\x00'         >> /tmp/msg.txt
	#/bin/echo -n -e '\x00\x00\x00\xBB' >> /tmp/msg.txt
	#cat tst/sub.lua                    >> /tmp/msg.txt
	#cat /tmp/msg.txt | nc localhost 8400
	#
	# REQUIRES DETERMINISTIC
	#/bin/echo -n PS                    >  /tmp/msg.txt
	#/bin/echo -n -e '\xF0\x00'         >> /tmp/msg.txt
	#/bin/echo -n -e '\x00\x00\x01\x29' >> /tmp/msg.txt
	#cat tst/pub-rem.lua                >> /tmp/msg.txt
	#cat /tmp/msg.txt | nc localhost 8400
	#
	#/bin/echo -n PS                    >  /tmp/msg.txt
	#/bin/echo -n -e '\xF0\x00'         >> /tmp/msg.txt
	#/bin/echo -n -e '\x00\x00\x00\xBD' >> /tmp/msg.txt
	#cat tst/pub-new.lua                >> /tmp/msg.txt
	#cat /tmp/msg.txt | nc localhost 8400
	#
	/bin/echo -n PS                    >  /tmp/msg.txt
	/bin/echo -n -e '\xF0\x00'         >> /tmp/msg.txt
	/bin/echo -n -e '\x00\x00\x00\x26' >> /tmp/msg.txt
	cat tst/atom.lua                   >> /tmp/msg.txt
	cat /tmp/msg.txt | nc localhost 8400
	#
	#echo 38             > /tmp/freechains/8400/fifo.in
	#cat tst/atom.lua    > /tmp/freechains/8400/fifo.in
	#echo 189            > /tmp/freechains/8400/fifo.in
	#cat tst/pub-new.lua > /tmp/freechains/8400/fifo.in

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
