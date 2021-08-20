using LightGraphs, GraphMakie, NetworkLayout, GLMakie

function to_graph(is::InventorySystem)
    g = SimpleDiGraph(0)
    dict = IdDict()
    dict2 = Dict()
    for (i,v) in enumerate(is.bom)
        add_vertex!(g)
        dict[v] = i
        dict2[i] = v
    end
    for v in is.bom
        for c in InventoryModels.children(v)
            add_edge!(g, dict[c], dict[v])
        end
    end
    return g,dict2
end

struct ISLayout
end

function (l::ISLayout)(g)
    layout(l, g)
end

function layout(::ISLayout, g)
    rows = Vector{Int}[]
    laidnodes = Set{Int}()
    while length(laidnodes) < maximum(vertices(g))
        toprow = Int[]
        push!(rows, toprow)
        for v in vertices(g)
            if (isempty(g.fadjlist[v]) || (all(f-> (f in laidnodes), g.fadjlist[v]) && all(f -> !(f in toprow), g.fadjlist[v]))) && !(v in laidnodes) 
                push!(toprow, v)
                push!(laidnodes, v)
            end
        end
    end
    nrows = length(rows)
    pos = Vector{Tuple{Float64,Float64}}(undef, nv(g))
    largest = maximum(length.(rows))
    center = iseven(largest) ? largest/2 : ceil(largest/2)
    for (i,row) in enumerate(rows)
        for (j,v) in enumerate(row)
            x = length(row) == 1 ? center : largest/length(row) + j - 1
            pos[v] = (x, nrows - i)
        end
    end
    pos
end

function draw_graph(is::InventorySystem)
    g,dict = to_graph(is)
    layout = ISLayout()
    f,a,p = graphplot(g, layout = layout,nlabels=[dict[i].name for i in 1:nv(g)], nodesize = 15, arrow_shift = 0.9, )
    hidespines!(a); hidedecorations!(a)
    display(f)
    f,a,p
end