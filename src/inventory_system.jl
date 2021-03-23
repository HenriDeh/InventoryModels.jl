mutable struct InventorySystem
    t::Int
    T::Int
    bom::Vector{BOMElement}
end

function InventorySystem(T, bom::Vector{BOMElement})
    maxT = T == Inf ? typemax(Int) : Int(T)
    bom_to = topological_order(bom)
    InventorySystem(1, maxT, bom_to)
end
function InventorySystem(T, bom::BOMElement...)
    InventorySystem(T, [bom...])
end

observe(is::InventorySystem) = reduce(vcat, observe.(is.bom))
observation_size(is::InventorySystem) = sum(observation_size.(is.bom))
action_size(is::InventorySystem)::Int = sum(action_size.(is.bom))

function (is::InventorySystem)(action::AbstractVector)
    @assert is.t <= is.T "InventorySystem is at terminal state, please use reset!(::InventorySystem)"
    @assert action_size(is) == length(action) "action must be of length $(action_size(is))"
    actions = Iterators.Stateful(action)
    for (elemement, act_size) in zip(is.bom, action_size.(is.bom))
        activate!(elemement, Iterators.take(actions, act_size))
    end
    for element in Iterators.reverse(is.bom)
        dispatch!(element)
    end
    is.t += 1
    return sum(reward!.(is.bom))
end

(is::InventorySystem)(action::AbstractMatrix) = is(vec(action))

function reset!(is::InventorySystem)
    reset!.(is.bom)
    is.t = 1
end

function topological_order(bom)
    L = eltype(bom)[]
    unmarked = Set(bom)
    tempmarked = Set()
    permarked = Set()
    function visit(node)
        if node in permarked
            return nothing
        elseif node in tempmarked
            throw("Node $node was visited multiple times during topological sorting. The BOM contains a cycle.")
        end
        push!(tempmarked, node)
        for child in children(node)
            visit(child)
        end
        push!(permarked, pop!(tempmarked, node))
        push!(L, node)
    end
    while !(isempty(unmarked) && isempty(tempmarked))
        node = pop!(unmarked)
        visit(node)
    end 
    return reverse(L)
end
