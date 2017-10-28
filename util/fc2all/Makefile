test:
	lua5.3 util/fc2all/fc2all.lua tst/tst-02.lua tst/tst-01.out
	echo "p\np" | mail | grep -v "/var/mail/chico\|     1 Mail System Intern\|^>N\|^ N\|^Date\|with LMTP id\|for <chico@localhost>\|BRT\|^Message-Id:\|^X-IMAPbase\|^X-UID\|^Saved\|^Held" | diff - util/fc2all/tst-01.out
