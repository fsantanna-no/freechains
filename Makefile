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
	for i in tst/*.ceu; do								\
		echo;											\
		echo "#####################################";	\
		echo File: "$$i";								\
		echo "#####################################";	\
		make SRC=$$i all || exit 1;						\
	done

include $(UV_DIR)/Makefile
