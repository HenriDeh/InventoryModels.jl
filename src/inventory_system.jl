mutable struct InventorySystem
    t::Int
    T::Int
    bom::Vector{AbstractItem}
    constraints::Vector{AbstractConstraint}
    reward::Float64
end

function InventorySystem(T, bom::Vector{<:AbstractItem}, constraints = AbstractConstraint[])
    constraint_names = unique(map(c -> getfield(c, :name), constraints))
    if length(constraint_names) < length(constraints) || "" in constraint_names
        for (i,c) in enumerate(constraints)
            if c.name == ""
                c.name = "constraint_$i"
            else
                c.name *= "$i"
            end
        end
    end
    item_names = unique(map(it -> getfield(it, :name), bom))
    if length(item_names) < length(bom) || "" in item_names
        for (i,it) in enumerate(bom)
            if it.name == ""
                it.name = "item_$i"
            else
                it.name *= "$i"
            end
        end
    end
    maxT = T == Inf ? typemax(Int) : Int(T)
    bom_to = topological_order(bom)
    InventorySystem(1, maxT, bom_to, constraints, 0.)
end

state(is::InventorySystem) = reduce(vcat, map(state,is.bom))
state_size(is::InventorySystem) = sum(map(state_size,is.bom))
action_size(is::InventorySystem)::Int = sum(map(action_size, is.bom))
is_terminated(is::InventorySystem) = is.t > is.T
reward(is::InventorySystem) = is.reward
print_state(is::InventorySystem) = reduce(vcat, map(print_state, is.bom))
print_action(is::InventorySystem) = reduce(vcat, map(print_action, is.bom))

function compute_quantities(is,action)
    actions = Iterators.Stateful(action)
    quantity = IdDict{AbstractItem, Vector{Float64}}()
    for item in is.bom
        act_size = action_size(item)
        Qs = Float64[]
        for polparams in partition(Iterators.take(actions, act_size), action_size(item.policy))
            push!(Qs, item.policy(item, polparams...))
        end
        quantity[item] = Qs
    end
    return quantity
end

function (is::InventorySystem)(action::AbstractVector)
    @assert !is_terminated(is) "InventorySystem is at terminal state, please use reset!(::InventorySystem)"
    @assert action_size(is) == length(action) "action must be of length $(action_size(is))"
    quantity = compute_quantities(is, action)
    #Stage: PreActStage
    for item in is.bom
        item(quantity[item])
    end
    #Stage: PreConsStage
    for cons in is.constraints
        cons()
    end
    #Stage: PreDispatchStage
    for item in Iterators.reverse(is.bom)
        dispatch!(item)
    end
    #Stage: PreRewardStage
    is.t += 1
    is.reward = sum(reward!.(is.bom))
end

(is::InventorySystem)(action::AbstractMatrix) = is(vec(action))

function reset!(is::InventorySystem)
    reset!.(is.bom)
    reset!.(is.constraints)
    is.t = 1
end

function topological_order(bom)
    L = eltype(bom)[]
    unmarked = copy(bom)
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

Base.show(io::IO, is::InventorySystem) = print(io, "InventorySystem(", is.T," periods, ", length(is.bom) ," items, (1x$(state_size(is))) state, ($(action_size(is))) action)")
