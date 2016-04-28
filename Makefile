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
C_FLAGS += -Isrc/ -llua5.1 -lsodium

_all: all

include $(UV_DIR)/Makefile
