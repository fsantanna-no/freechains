#CEU_DIR    = $(error set absolute path to "<ceu>" repository)
#CEU_UV_DIR = $(error set absolute path to "<ceu-libuv>" repository)
CEU_DIR      = /data/ceu/ceu
CEU_UV_DIR   = /data/ceu/ceu-libuv
CEU_FC_DIR   = $(CEU_UV_DIR)/ceu-libuv-freechains
CEU_FCFS_DIR = $(CEU_FC_DIR)/util/fcfs

main:
	make CEU_SRC=src/main.ceu all

all:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=$(CEU_SRC)                                           \
	    --ceu --ceu-features-lua=true --ceu-features-thread=true               \
	          --ceu-err-unused=pass --ceu-err-uninitialized=pass               \
	    --env --env-types=$(CEU_DIR)/env/types.h                               \
	          --env-threads=$(CEU_UV_DIR)/env/threads.h                        \
	          --env-main=$(CEU_DIR)/env/main.c                                 \
	    --cc --cc-args="-lm -llua5.3 -luv -lsodium -g"                         \
	         --cc-output=freechains

ceu:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=$(CEU_SRC)  --pre-output=/tmp/x.ceu \
	    --ceu --ceu-input=/tmp/x.ceu --ceu-features-lua=true --ceu-features-thread=true               \
	          --ceu-err-unused=pass --ceu-err-uninitialized=pass               \
	          --ceu-line-directives=false \
	    --env --env-types=$(CEU_DIR)/env/types.h                               \
	          --env-threads=$(CEU_UV_DIR)/env/threads.h                        \
	          --env-main=$(CEU_DIR)/env/main.c  --env-output=/tmp/x.c                                \
	    --cc --cc-args="-lm -llua5.3 -luv -lsodium -g"							   \
	         --cc-output=freechains

c:
	ceu --cc --cc-input=/tmp/x.c --cc-args="-lm -llua5.3 -luv -lsodium -g"							   \
	         --cc-output=freechains

tests: fifo
	for i in tst/tst-*.ceu; do                           \
		echo;                                            \
		echo "#####################################";    \
		echo File: "$$i";                                \
		echo "#####################################";    \
		make CEU_SRC=$$i all && ./freechains || exit 1;  \
		if [ "$$i" = "tst/tst-32.ceu" ]; then break; fi; \
	done

milter:
	cd $(CEU_DIR) && make CEU_SRC=$(CEU_FC_DIR)/util/milter.ceu CC_ARGS="-lmilter" one
	mv -f /tmp/milter milter
	#sudo chown postfix milter
	#sudo chmod 4755 milter

fcfs:
	cd $(CEU_DIR) && make CEU_SRC=$(CEU_FCFS_DIR)/bbfs.ceu CC_ARGS="-I$(CEU_FCFS_DIR)/ -D_FILE_OFFSET_BITS=64 -lfuse" one
	mv -f /tmp/bbfs fcfs

run: fifo
	./freechains cfg/config-01.lua /tmp/fifo.in /tmp/fifo.out &
	sudo rm -f /var/spool/postfix/milters/freechains.milter
	./milter chico /tmp/fifo.in &
	sleep 1
	sudo chmod 777 /var/spool/postfix/milters/freechains.milter
	lua5.3 util/fc2all.lua cfg/config-01.lua /tmp/fifo.out &
	./fcfs $(CEU_FCFS_DIR)/root1 $(CEU_FCFS_DIR)/mount1 /tmp/fifo.in
	echo "--- ENTER TO KILL ALL ---"
	read v
	make kill

fifo:
	rm -f /tmp/fifo.*
	mkfifo /tmp/fifo.in
	mkfifo /tmp/fifo.out

kill:
	- killall milter
	- pkill -f freechains
	- pkill -f fc2all
	- fusermount -u /data/tmp/mount1
	- pkill -f fcfs

.PHONY: milter fcfs

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
