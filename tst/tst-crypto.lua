FC = require 'freechains'

DAEMON = {
    address = 'localhost',
    port    = 8400,
}

-- CREATE

local shared = FC.send(0x0700, {
    create     = 'shared',
    passphrase = 'senha',
}, DAEMON)

assert(shared == 'CA276C07F49096AC2D9D00AA42651B309AA116C4157A95A5DB33279D3ED93A01')

local pubpvt = FC.send(0x0700, {
    create     = 'public-private',
    passphrase = 'senha',
}, DAEMON)

assert(pubpvt.public  == '56D7DE5188D609905DAB9D86701FA3F78692DCA79969C7C2EC29C1D023F2757B')
assert(pubpvt.private == 'CA276C07F49096AC2D9D00AA42651B309AA116C4157A95A5DB33279D3ED93A0156D7DE5188D609905DAB9D86701FA3F78692DCA79969C7C2EC29C1D023F2757B')

-- SHARED

local ret = FC.send(0x0700, {
    encrypt = 'shared',
    key     = shared,
    payload = 'Ola Mundo!',
}, DAEMON)

assert(ret ~= 'Ola Mundo!')

local ret = FC.send(0x0700, {
    decrypt = 'shared',
    key     = shared,
    payload = ret,
}, DAEMON)

assert(ret == 'Ola Mundo!')

-- SEALED

local ret = FC.send(0x0700, {
    encrypt = 'sealed',
    pub     = pubpvt.public,
    payload = 'Ola Mundo!',
}, DAEMON)

assert(ret ~= 'Ola Mundo!')

local ret = FC.send(0x0700, {
    decrypt = 'sealed',
    pub     = pubpvt.public,
    pvt     = pubpvt.private,
    payload = ret,
}, DAEMON)

assert(ret == 'Ola Mundo!')

-- PUBLIC-PRIVATE

local other = FC.send(0x0700, {
    create     = 'public-private',
    passphrase = 'other',
}, DAEMON)

local ret = FC.send(0x0700, {
    encrypt = 'public-private',
    pub     = pubpvt.public,
    pvt     = other.private,
    payload = 'Ola Mundo!',
}, DAEMON)

assert(ret ~= 'Ola Mundo!')

local ret = FC.send(0x0700, {
    decrypt = 'public-private',
    pub     = other.public,
    pvt     = pubpvt.private,
    payload = ret,
}, DAEMON)

assert(ret == 'Ola Mundo!')


