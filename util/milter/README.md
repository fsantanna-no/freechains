Intercepts e-mails and redirects to *freechains*:

```
$ ./milter chico /tmp/xxx
```

- `chico`: user to intercept e-mails from.
- `/tmp/xxx`: file to communicate with FC.

# INSTALL

```
$ make CEU_SRC=<.>/util/milter.ceu CC_ARGS="-lmilter" one
$ vi /etc/postfix/main.cf
    - smtpd_milters = unix:/milters/freechains.milter
    - non_smtpd_milters = unix:/milters/freechains.milter
```

# TESTING

```
$ sudo rm -f /var/spool/postfix/milters/freechains.milter
$ ./milter chico /tmp/xxx &
$ sleep 1
$ sudo chmod 777 /var/spool/postfix/milters/freechains.milter
$ ls -l /var/spool/postfix/milters/freechains.milter

$ touch /tmp/xxx
$ tail -f /tmp/xxx

# FC2MAIL   | USER -> USER     | accept and don't forward to FC
$ echo teste-1 | mail chico -s TESTE-1

# FETCHMAIL | * -> USER        | discard and forward to FC
# FC        | * -> @freechains | discard and forward to FC
# NORMAL    | * -> *           | accept  and forward to FC
$ echo teste-2 | mail chico -s TESTE-2 -a "From: other@other.com"
$ echo teste-3 | mail " |chico|0|@freechains.org" -s TESTE-3
$ echo teste-4 | mail francisco.santanna@gmail.com -s TESTE-4
```
