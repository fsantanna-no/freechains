Intercepts e-mails and redirects to *freechains*:

```
$ ./milter <user> <fc-output-file>
```

- `<user>`: user to intercept e-mails from
- `<fc-output-file>`: file to communicate with *freechains*

# Install

```
$ vi /etc/postfix/main.cf
    - smtpd_milters = unix:/milters/freechains.milter
    - non_smtpd_milters = unix:/milters/freechains.milter
$ make
$ make test
```

# Rules

```
# FC2MAIL   | USER -> USER     | accept and don't forward to FC
$ echo teste-1 | mail chico -s TESTE-1

# FETCHMAIL | * -> USER        | discard and forward to FC
# FC        | * -> @freechains | discard and forward to FC
# NORMAL    | * -> *           | accept  and forward to FC
$ echo teste-2 | mail chico -s TESTE-2 -a "From: other@other.com"
$ echo teste-3 | mail " |chico|0|@freechains.org" -s TESTE-3
$ echo teste-4 | mail francisco.santanna@gmail.com -s TESTE-4
```
