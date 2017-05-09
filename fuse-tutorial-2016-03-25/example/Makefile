CEU_DIR    = /data/ceu/ceu
CEU_UV_DIR = /data/ceu/ceu-libuv
CEU_FUSE_DIR = $(CEU_UV_DIR)/ceu-libuv-freechains/fuse-tutorial-2016-03-25

all:
	mkdir -p mountdir
	mkdir -p rootdir
	echo "bogus file" > rootdir/bogus.txt

distdir:
	cp Makefile $(distdir)

mostlyclean clean distclean mainainer-clean:
	rm -r mountdir rootdir

start:
	./bbfs $(CEU_FUSE_DIR)/example/rootdir $(CEU_FUSE_DIR)/example/mountdir /tmp/fifo.in

stop:
	fusermount -u mountdir

ceu:
	cd $(CEU_DIR) && make CEU_SRC=$(CEU_FUSE_DIR)/src/bbfs.ceu CC_ARGS="-I$(CEU_FUSE_DIR)/src/ -D_FILE_OFFSET_BITS=64 -lfuse" one
	mv -f /tmp/bbfs bbfs
