local INPUT = table.unpack(arg)
local fin = assert(io.open(INPUT, 'r+'))

while true do
    local buf, chain_id do
        chain_id = assert(fin:read('l'))
        local n = assert(tonumber(assert(fin:read('l'))))
        buf = fin:read(n)
        --print(n)
        --print(buf)
    end

    if chain_id == '|fs|0|' then
        local i = string.find(buf, '\n', 1, true)
        local name = string.sub(buf, 1,i-1)
        local contents = string.sub(buf,i+1)
        local dir = string.match(name, '(.-)[^/]*$')
        os.execute('rm -Rf '..name)
        os.execute('mkdir -p /tmp/'..dir)
        local fout = assert(io.open('/tmp/'..name, 'w'))
        fout:write(contents)
        fout:close()
    else
        print'=== FC2MAIL'
        --local fout = assert(io.popen('mail --subject="Freechains" user', 'w'))
        local fout = assert(io.popen('sendmail -t', 'w'))
        fout:write(buf)
        fout:close()
    end
end
