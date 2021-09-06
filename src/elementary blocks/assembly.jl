mutable struct Assembly{F, L<:LeadTime, C <: Tuple}
    production_cost::F
    capacity::Float64
    leadtime::L
    components::C
    requirements::IdDict{Any, Float64}
    pull_orders::IdDict{Any,Float64}
    batchsize_log::Vector{Float64}
    cost_log::Vector{Float64}
    name::String
end

function Assembly(production_cost, components::Pair{<:Any, <:Number}...; leadtime = LeadTime(0,0), capacity = Inf, name = "assembly")
    @assert hasmethod(production_cost, Tuple{Assembly}) "production_cost must have a method with (::Assembly) signature"
    @assert length(components) >= 1 "Assembly must have at least one component"
    comps = tuple([first(pair) for pair in components]...)
    Assembly(production_cost, Float64(capacity), leadtime, comps, IdDict{Any, Float64}(components), IdDict{Any,Float64}(), zeros(0), zeros(0), name)
end

function Assembly(fixed_order_cost::Number, variable_order_cost::Number, components::Pair{<:Any, <:Number}...; leadtime = LeadTime(0,0), capacity = Inf, name = "assembly")
    Assembly(FixedLinearOrderCost(fixed_order_cost, variable_order_cost), components..., leadtime = leadtime, capacity = capacity, name = name)
end

state(a::Assembly) = state(a.leadtime)
state_size(a::Assembly) = state_size(a.leadtime)
print_state(a::Assembly) = print_state(a.leadtime)

function pull!(ass::Assembly, quantity::Number, issuer)
    @assert 0 == length(ass.pull_orders) "assembly received multiple orders"
    push!(ass.pull_orders, issuer => min(quantity, ass.capacity))
    destination, quantity = first(ass.pull_orders)
    for (component, required) in ass.requirements
        pull!(component, quantity*required, ass)
    end
    nothing
end

function Base.push!(ass::Assembly, quantity, source)
    ass.pull_orders[source] = quantity
    nothing
end

function dispatch!(ass::Assembly)
    destination = only(setdiff(keys(ass.pull_orders), (c.inventory for c in ass.components)))
    quantity = ass.pull_orders[destination]
    for (component, required) in ass.requirements
        quantity = min(quantity, ass.pull_orders[component.inventory]/required)
    end
    for (component, required) in ass.requirements
        excess = pop!(ass.pull_orders, component.inventory) - required*quantity
        push!(component.inventory, excess, ass)
    end 
    ass.pull_orders[destination] = quantity
    push!(ass.batchsize_log, quantity)
    push!(ass.leadtime, quantity, destination)
    dispatch!(ass.leadtime)
    nothing
end

function reward!(ass::Assembly)
    cost = ass.production_cost(ass)
    push!(ass.cost_log, cost)
    empty!(ass.pull_orders)
    
    return -cost + reward!(ass.leadtime)
end

inventory_position(ass::Assembly) = inventory_position(ass.leadtime)

function reset!(a::Assembly) 
    empty!(a.cost_log)
    empty!(a.batchsize_log)
    reset!(a.leadtime)
end

children(ass::Assembly) = ass.components

#cost functions defined in supplier.jl
function (f::FixedLinearOrderCost)(ass::Assembly) 
    q = sum(values(ass.pull_orders))
    return (q > 0)*(f.K + f.c*q)
end

(f::LinearOrderCost)(ass::Assembly) = f.c*sum(values(ass.pull_orders))

Base.show(io::IO, ass::Assembly{F}) where {F} = print(io, "Assembly($(ass.name), $F, $(ass.leadtime.leadtime))")