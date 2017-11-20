-- TODO:
--  - afastar fim da aresta do nó
--  - render respeitar profundidade (desenhar nos com mesma profundidade na mesma altura)
--  - DOTTY
--      - remover O do inicio das arestas
--      - incluir labels nos nos

G = { tp='genesis', height=0, label='G' }

SHAPE = {
    genesis   = 'invtriangle',
    pub       = 'circle',
    join_fork = 'diamond',
    head      = 'point',
}

local n = 0
local nodes = {}
local conns = {}

function dot (node)
    if node.__n then
        return '',''
    end
    node.__n = 'n_'..n
    n = n + 1

    for _, child in ipairs(node) do
        local ss, cs = dot(child)
        nodes[#nodes+1] = ss
        conns[#conns+1] = cs
        conns[#conns+1] = node.__n..' -> '..child.__n
    end

    nodes[#nodes+1] = node.__n..'[label="'..node.label..'/'..node.height..'", shape='..SHAPE[node.tp]..'];'
end

function MAX (a, b)
    return a>b and a or b
end

function contains (as, x)
    for h, a in ipairs(as) do
        if a == x then
            return h
        end
    end
    return false
end

local SEQ = 0
function remove_children (a)
    if a.__removed == SEQ then
        return
    end
    a.__removed = SEQ
    for _, x in ipairs(a) do
        remove_children(x)
    end
end

function walk (h, AS, BS)
    -- evaluate current height
    local as = AS[h]
    local bs = BS[h]
    for i=#as, 1, -1 do
        local a = as[i]
        if a.tp == 'pub' then
            -- a traversed "pub" remains as "togo"
        else
            assert(a.tp == 'join_fork', tostring(a))
            local idx = contains(bs,a)
print('CONTAINS', a.label, a.height, idx)
            if idx then
                -- found: remove and do not recurse
print'removed'
                table.remove(as, i)
                table.remove(bs, idx)
                remove_children(a)
            else
                -- not found: remains as "togo" and recurse
            end
        end
    end

    -- fill next lower height with children from remaining nodes
    for _,X in ipairs(as) do
        for _,x in ipairs(X) do
            local t = AS[x.height]
print('fill', x.label, x.height)
            if x.__removed ~= SEQ then
                t[#t+1] = x
            end
        end
    end
end

function join (A, B)
    SEQ = SEQ + 1
    assert(A.tp=='head' and B.tp=='head')
    local a = A[1]
    local b = B[1]
    assert(a ~= b)

    local ret = { a,b, tp='join_fork', height=MAX(a.height,b.height)+1, label=a.label..b.label }
    A[1] = ret
    B[1] = ret

    local AS = {
        [0] = { G },
        [a.height] = { a },
    }
    local BS = {
        [0] = { G },
        [b.height] = { b },
    }

    local max = MAX(a.height, b.height)

    for h=1, max do
        AS[h] = AS[h] or {}
        BS[h] = BS[h] or {}
    end

    for h=max, 1, -1 do
print('>>> AS', h)
        walk(h, AS, BS)
print('>>> BS', h)
        walk(h, BS, AS)
    end

    print'>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
    for i=1, a.height do
        local as = AS[i]
        print('--- '..i)
        for j=1, #as do
            print('-> '..as[j].label)
        end
    end
    print'-----------------------------'
    for i=1, b.height do
        local bs = BS[i]
        print('--- '..i)
        for j=1, #bs do
            print('-> '..bs[j].label)
        end
    end
    print'<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
end

function head (label, H)
    return { (H or G), tp='head', height=-1, label=label }
end

function pub (H, label)
    local n = { H[1], tp='pub', height=(H[1].height+1), label=label }
    H[1] = n
end

-------------------------------------------------------------------------------

if true then

    A = head('A')
    pub(A, 'a1')

    B = head('B')
    pub(B, 'b1')

    C = head('C')
    pub(C, 'c1')

    print('-=-= A-B =-=-')
    join(A,B)

    pub(A, 'a2')
    pub(B, 'b2')

    print('-=-= C-B =-=-')
    join(C,B)

    pub(C, 'c2')
    pub(B, 'b3')

    print('-=-= A-B =-=-')
    join(A,B)

    pub(A, 'a3')
    join(A,C)

    D = head('D', B[1])
    pub(D, 'd1')
    join(D,C)

    dot(A) dot(B) dot(C) dot(D)

else

    A = head('A')
    B = head('B')
    C = head('C')
    D = head('D')
    E = head('E')
    F = head('F')

    pub(A, 'a1')
    pub(B, 'b1')
    pub(C, 'c1')
    pub(D, 'd1')
    pub(E, 'e1')
    pub(F, 'f1')

    join(E,F)
    join(C,D)
    join(C,E)
    join(A,B)
    join(A,C)

    dot(A) --dot(B) dot(C)
end

-------------------------------------------------------------------------------

local f = io.open('/tmp/x.dot', 'w')
f:write([[
digraph graphname {
    //rankdir=LR;  // Rank Direction Left to Right

    nodesep=1.0 // increases the separation between nodes
    edge [];
    //splines = true;

    ]]..table.concat(nodes,'\n')..[[

    ]]..table.concat(conns,'\n')..[[

}
]])
