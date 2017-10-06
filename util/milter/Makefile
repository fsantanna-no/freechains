#CEU_DIR    = $(error set absolute path to "<ceu>" repository)
#CEU_UV_DIR = $(error set absolute path to "<ceu-libuv>" repository)
CEU_DIR      = /data/ceu/ceu
CEU_UV_DIR   = /data/ceu/ceu-libuv
CEU_MILTER_DIR = /data/ceu/ceu-libuv/ceu-libuv-freechains/util/milter

milter:
	cd $(CEU_DIR) && make CEU_SRC=$(CEU_MILTER_DIR)/milter.ceu CEU_ARGS="--ceu-features-lua=true" CC_ARGS="-lmilter" one
	mv -f /tmp/milter milter

test:
	sudo rm -f /var/spool/postfix/milters/freechains.milter
	rm -f /tmp/milter.test.out
	./milter chico /tmp/milter.test.out &
	sleep 1
	sudo chmod 777 /var/spool/postfix/milters/freechains.milter
	ls -l /var/spool/postfix/milters/freechains.milter
	#
	echo teste-1 | mail chico -s TESTE-1                              # accept, no fc
	echo teste-2 | mail chico -s TESTE-2 -a "From: other@other.com"   # discard, fc.|chico|
	echo teste-3 | mail " ||0|@freechains.org" -s TESTE-3             # discard, fc.||
	echo teste-4 | mail francisco.santanna@gmail.com -s TESTE-4       # accept, fc.|chico|
	echo CHECK YOUR GMAIL FOR TESTE-4!!!
	sleep 1
	#
	echo p | mail | grep -v "/var/mail/chico\|     1 Mail System Intern\|^>N\|^Date\|with LMTP id\|for <chico@localhost>\|BRT\|^Message-Id:\|^X-IMAPbase\|^X-UID\|^Saved" | diff - test-01.out
	cat /tmp/milter.test.out | grep -v "Message-Id:\|Date:" | diff - milter.test.out

.PHONY: milter
