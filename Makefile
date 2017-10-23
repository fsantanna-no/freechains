#CEU_DIR    = $(error set absolute path to "<ceu>" repository)
#CEU_UV_DIR = $(error set absolute path to "<ceu-libuv>" repository)
CEU_DIR      = /data/ceu/ceu
CEU_UV_DIR   = /data/ceu/ceu-libuv
CEU_FC_DIR   = $(CEU_UV_DIR)/ceu-libuv-freechains
CEU_FCFS_DIR = $(CEU_FC_DIR)/util/fcfs

main:
	make CEU_SRC=src/main.ceu all
	cp /tmp/main freechains

all:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=$(CEU_SRC)                                           \
	    --ceu --ceu-features-lua=true --ceu-features-thread=true               \
		      --ceu-features-trace=true \
		      --ceu-features-exception=true --ceu-err-uncaught-exception-main=pass --ceu-err-uncaught-exception-lua=pass \
	          --ceu-err-unused=pass --ceu-err-uninitialized=pass               \
	          --ceu-line-directives=true \
	    --env --env-types=$(CEU_DIR)/env/types.h                               \
	          --env-threads=$(CEU_UV_DIR)/env/threads.h                        \
	          --env-main=$(CEU_DIR)/env/main.c   --env-output=/tmp/x.c         \
	    --cc --cc-args="-lm -llua5.3 -luv -lsodium -g"                         \
			 --cc-output=/tmp/$$(basename $(CEU_SRC) .ceu);

ceu:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=$(CEU_SRC)  --pre-output=/tmp/x.ceu                  \
	    --ceu --ceu-input=/tmp/x.ceu --ceu-features-lua=true --ceu-features-thread=true \
	          --ceu-err-unused=pass --ceu-err-uninitialized=pass               \
	          --ceu-line-directives=false                                      \
	    --env --env-types=$(CEU_DIR)/env/types.h                               \
	          --env-threads=$(CEU_UV_DIR)/env/threads.h                        \
	          --env-main=$(CEU_DIR)/env/main.c  --env-output=/tmp/x.c          \
	    --cc --cc-args="-lm -llua5.3 -luv -lsodium -g"                         \
			 --cc-output=/tmp/$$(basename $(CEU_SRC) .ceu);

tst-cmds:
	echo 38             > /tmp/freechains/8400/fifo.in
	cat tst/atom.lua    > /tmp/freechains/8400/fifo.in
	echo 185            > /tmp/freechains/8400/fifo.in
	cat tst/pub.lua     > /tmp/freechains/8400/fifo.in
	echo 226            > /tmp/freechains/8400/fifo.in
	cat tst/pub-sub.lua > /tmp/freechains/8400/fifo.in
	echo 177            > /tmp/freechains/8400/fifo.in
	cat tst/pub-5.lua   > /tmp/freechains/8400/fifo.in
	echo 187            > /tmp/freechains/8400/fifo.in
	cat tst/sub.lua     > /tmp/freechains/8400/fifo.in
	echo 189            > /tmp/freechains/8400/fifo.in
	cat tst/pub-new.lua > /tmp/freechains/8400/fifo.in

c:
	ceu --cc --cc-input=/tmp/x.c --cc-args="-lm -llua5.3 -luv -lsodium -g"     \
	         --cc-output=freechains

tests:
	rm -Rf /tmp/fc-*/
	mkdir /tmp/fc-01/ /tmp/fc-02/
	mkfifo /tmp/fc-02/fifo.in
	make milter
	- killall freechains
	sleep 1
	./freechains tst/tst-02.lua /tmp/fc-02/fifo.in /tmp/fc-02/tst-01.out &
	sleep 1
	./freechains tst/tst-01.lua util/milter/milter.test.out.orig /tmp/fc-01/tst-01.out
	#
	diff /tmp/fc-01/\|\|0\|.chain tst/\|\|0\|.chain
	diff /tmp/fc-01/\|chico\|0\|.chain tst/\|chico\|0\|.chain
	diff /tmp/fc-01/tst-01.out tst/tst-01.out
	#
	diff /tmp/fc-0*/\|\|0\|.chain
	diff /tmp/fc-0*/\|chico\|0\|.chain
	diff /tmp/fc-0*/tst-01.out
	#
	- killall freechains
	make -f util/fc2all/Makefile
	#exit 1
	#
	make tst

tst:
	for i in tst/tst-[0-2]*.ceu tst/tst-3[0-4].ceu tst/tst-a*.ceu; do \
		echo;                                            \
		echo "#####################################";    \
		echo File: "$$i";                                \
		echo "#####################################";    \
		make CEU_SRC=$$i all && /tmp/$$(basename $$i .ceu) || exit 1; \
	done

tst-run:
	for i in tst/tst-[0-2]*.ceu tst/tst-3[0-4].ceu tst/tst-a*.ceu; do \
		echo;                                            \
		echo "#####################################";    \
		echo File: "$$i";                                \
		echo "#####################################";    \
		/tmp/$$(basename $$i .ceu) || exit 1;            \
	done

milter:
	- killall milter
	sleep 5
	sudo rm -f /var/spool/postfix/milters/freechains.milter
	./milter chico util/milter/FIFO &
	sleep 2
	sudo chmod 777 /var/spool/postfix/milters/freechains.milter
	ls -l /var/spool/postfix/milters/freechains.milter

fcfs:
	cd $(CEU_DIR) && make CEU_SRC=$(CEU_FCFS_DIR)/bbfs.ceu CC_ARGS="-I$(CEU_FCFS_DIR)/ -D_FILE_OFFSET_BITS=64 -lfuse" one
	mv -f /tmp/bbfs fcfs

run: fifo
	./freechains cfg/config-01.lua /tmp/fifo-01.in /tmp/fifo-01.out &
	sudo rm -f /var/spool/postfix/milters/freechains.milter
	./milter chico /tmp/fifo-01.in &
	sleep 1
	sudo chmod 777 /var/spool/postfix/milters/freechains.milter
	lua5.3 util/fc2all.lua cfg/config-01.lua /tmp/fifo-01.out &
	./fcfs $(CEU_FCFS_DIR)/root-01 $(CEU_FCFS_DIR)/mount-01 /tmp/fifo-01.in
	ls -l /var/spool/postfix/milters/freechains.milter
	#
	#./freechains cfg/config-02.lua /tmp/fifo-02.in /tmp/fifo-02.out &
	#lua5.3 util/fc2all.lua cfg/config-02.lua /tmp/fifo-02.out &
	#./fcfs $(CEU_FCFS_DIR)/root-02 $(CEU_FCFS_DIR)/mount-02 /tmp/fifo-02.in
	#
	echo "--- ENTER TO KILL ALL ---"
	read v
	make kill

r2e:
	make milter
	- killall freechains
	- pkill -9 -f fc2all
	sleep 2
	./freechains util/r2e/r2e.lua util/milter/FIFO util/r2e/FIFO &
	lua5.3 util/fc2all/fc2all.lua util/r2e/r2e.lua util/r2e/FIFO &
	sleep 2
	cp ~/.local/share/rss2email.json util/r2e/bak/rss2email.json.`date +%Y%m%d.%s`
	cp ~/.config/rss2email.cfg util/r2e/bak/rss2email.cfg.`date +%Y%m%d.%s`
	- cp util/r2e/\|chico\|0\|.chain util/r2e/bak/\|chico\|0\|.chain.`date +%Y%m%d.%s`
	- cp util/r2e/\|others\|0\|.chain util/r2e/bak/\|others\|0\|.chain.`date +%Y%m%d.%s`
	r2e run

fifo:
	rm -f /tmp/fifo-*.*
	mkfifo /tmp/fifo-01.in
	mkfifo /tmp/fifo-01.out
	mkfifo /tmp/fifo-02.in
	mkfifo /tmp/fifo-02.out

kill:
	- pkill -9 -f milter
	- pkill -9 -f freechains
	- pkill -9 -f fc2all
	#- fusermount -u /data/tmp/mount-01
	#- fusermount -u /data/tmp/mount-02
	#- pkill -9 -f fcfs
	#- sudo umount /data/ceu/ceu-libuv/ceu-libuv-freechains/util/fcfs/mount*

.PHONY: milter fcfs r2e tst

# 01->32
#real	8m57.250s
#user	5m25.088s
#sys	0m10.500s
#---
#real	12m18.462s
#user	7m29.992s
#sys	0m9.432s
#---
#real	8m13.586s
#user	7m40.896s
#sys	0m9.088s

# 32
# 20*20=400 messages, 400*20=8000 minimum receives
# BLOCKS = 45634, 44450, 42336, 42175 (5.3x)
#real	4m1.622s
#user	2m23.344s
#sys	0m4.324s

# 35
# 7*7=49 messages, 49*7=343 minimum receives
# BLOCKS = 3081, 4012 (8.9x)
#real	0m39.997s
#user	0m15.252s
#sys	0m0.588s
