local CONFIG, INPUT = table.unpack(arg)

dofile 'src/common.lua'
dofile(CONFIG)

local fin = assert(io.open(INPUT, 'r+'))

while true do
    local buf, id do
        id = fin:read('l')
        if not id then
            break
        end
        local n = assert(tonumber(assert(fin:read('l'))))
        buf = fin:read(n)
        --print(n)
        --print(buf)
    end

    local chain = assert(APP.chains[id], 'invalid chain '..id)
    local sink_id = chain.sink and chain.sink.id

    if sink_id == 'fs' then
        print'=== FC2FS'
        local i = string.find(buf, '\n', 1, true)
        local name = string.sub(buf, 1,i-1)
        local contents = string.sub(buf,i+1)
        local dir = string.match(name, '(.-)[^/]*$')
        os.execute('rm -Rf '..chain.sink.dir..'/'..name)
        os.execute('mkdir -p '..chain.sink.dir..'/'..dir)
        --local fout = assert(io.open('/data/ceu/ceu-libuv/ceu-libuv-freechains/fuse-tutorial-2016-03-25/example/rootdir/'..name, 'w'))
        --fout:write(contents)
        --fout:close()
        local fout = assert(io.open(chain.sink.dir..'/'..name, 'w'))
        fout:write(contents)
        fout:close()
    elseif sink_id == 'mail' then
        print'=== FC2MAIL'
        --local fout = assert(io.popen('mail --subject="Freechains" user', 'w'))
        local fout = assert(io.popen('sendmail -t', 'w'))
        fout:write(buf)
        fout:close()
    else
        print'=== FC2???'
    end
end
