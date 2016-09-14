#CEU_DIR     = $(error set absolute path to "<ceu>" repository)
#CEU_SDL_DIR = $(error set absolute path to "<ceu-sdl>" repository)

CEU_DIR    = /data/ceu/ceu
CEU_UV_DIR = /data/ceu/ceu-libuv

C_FLAGS += -Isrc/ -llua5.3 -lsodium

all3:
	ceu --ceu --ceu-input=/tmp/tst.ceu \
	    --env --env-types=$(CEU_DIR)/env/types.h                        \
	          --env-threads=$(CEU_UV_DIR)/env/threads.h                 \
	          --env-main=$(CEU_DIR)/env/main.c                          \
	          --env-output=/tmp/tst.c                         \
	    --cc --cc-args="-lm -llua5.3 -luv -lsodium -g"                  \
	          --cc-output=/tmp/tst;                                     \
	/tmp/tst;                                                           \
	echo ">>> OK";

all4:
	ceu --cc --cc-input=/tmp/tst.c --cc-args="-lm -llua5.3 -luv -lsodium -g"                  \
	          --cc-output=/tmp/tst;                                     \
	/tmp/tst;                                                           \
	echo ">>> OK";

all2:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=tst/tst-00.ceu                                \
			  --pre-output=/tmp/tst.ceu; \
	echo ">>> OK";

all1:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=tst/tst-00.ceu                                \
	    --ceu                                                           \
	    --env --env-types=$(CEU_DIR)/env/types.h                        \
	          --env-threads=$(CEU_UV_DIR)/env/threads.h                 \
	          --env-main=$(CEU_DIR)/env/main.c                          \
	    --cc --cc-args="-lm -llua5.3 -luv -lsodium -g"                  \
	          --cc-output=/tmp/tst;                                     \
	/tmp/tst;                                                           \
	echo ">>> OK";

all:
	ceu --pre --pre-args="-I$(CEU_DIR)/include -I$(CEU_UV_DIR)/include -Isrc/" \
	          --pre-input=tst/tst-00.ceu                                \
	    --ceu                                                           \
	    --env --env-types=$(CEU_DIR)/env/types.h                        \
	          --env-threads=$(CEU_UV_DIR)/env/threads.h                 \
	          --env-main=$(CEU_DIR)/env/main.c                          \
	    --cc --cc-args="-lm -llua5.3 -luv -lsodium -g"                  \
	          --cc-output=/tmp/tst;                                     \
	/tmp/tst;                                                           \
	echo ">>> OK";

tests:
	for i in tst/*.ceu; do								\
		echo;											\
		echo "#####################################";	\
		echo File: "$$i";								\
		echo "#####################################";	\
		make SRC=$$i all || exit 1;						\
		if [ "$$i" = "tst/tst-32.ceu" ]; then break; fi; \
	done
	make SRC=tst/tst-35.ceu

tests-run:
	cd build && for i in tst-*.exe; do					\
		echo;											\
		echo "#####################################";	\
		echo File: "$$i";								\
		echo "#####################################";	\
		./$$i || exit 1;								\
		if [ "$$i" = "tst-32.exe" ]; then break; fi;	\
	done
	cd build && ./tst-35.exe

# 01->32,35
#real	9m29.783s
#user	5m24.168s
#sys	0m10.704s

# 32
# 20*20=400 messages, 400*20=8000 minimum receives
#BLOCKS_RECEIVED  = 44627,34144 (4.3x)
#BLOCKS_RECREATED = 3325,1990
#real	4m2.392s
#user	2m26.092s
#sys	0m4.400s

# 35
# 7*7=49 messages, 49*7=343 minimum receives
#BLOCKS_RECEIVED  = 2249,3510 (6.9x-10.2x)
#BLOCKS_RECREATED = 77,91,120
#real	0m39.689s
#user	0m14.656s
#sys	0m0.624s

# 01->32
#real	8m57.250s
#user	5m25.088s
#sys	0m10.500s


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
