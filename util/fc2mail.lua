local INPUT = table.unpack(arg)
local fin = assert(io.open(INPUT, 'r+'))

while true do
    local buf do
        local n = assert(tonumber(assert(fin:read('l'))))
        buf = fin:read(n)
        --print(n)
        --print(buf)
    end

    print'=== FC2MAIL'
    --local fout = assert(io.popen('mail --subject="Freechains" user', 'w'))
    local fout = assert(io.popen('sendmail -t', 'w'))
    fout:write(buf)
    fout:close()
end
