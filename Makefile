###############################################################################
# EDIT
###############################################################################

C_FLAGS ?= -DCEU_DEBUG -DDEBUG -g
UV_DIR = /data/ceu/ceu-libuv
#UV_DIR ?= $(error set absolute path to "<ceu-sdl>" repository)

###############################################################################
# DO NOT EDIT
###############################################################################

OUT_DIR = build
SRC = src/main.ceu
C_FLAGS += -Isrc/ -llua5.3 -lsodium

_all: all

tests:
	for i in tst/*.ceu; do					\
		echo;						\
		echo "#####################################";	\
		echo File: "$$i";				\
		echo "#####################################";	\
		make SRC=$$i all || exit 1;			\
		if [ "$$i" = "tst/tst-32.ceu" ]; then break; fi; \
	done

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




include $(UV_DIR)/Makefile
