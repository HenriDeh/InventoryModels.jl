mutable struct Assembly{F, C <: Tuple} <:BOMElement
    production_cost::F
    capacity::Float64
    components::C
    requirements::IdDict{Item, Float64}
    pull_orders::IdDict{Any,Float64}
    name::String
end

function Assembly(production_cost, components::Pair{<:Item, <:Number}...; capacity = Inf, name = "")
    @assert hasmethod(production_cost, Tuple{Assembly}) "production_cost must have a method with (::Assembly) signature"
    @assert length(components) >= 1 "Assembly must have at least one component"
    comps = tuple([first(pair) for pair in components]...)
    Assembly(production_cost, Float64(capacity), comps, IdDict{Item, Float64}(components), IdDict{Any,Float64}(), name)
end

function Assembly(fixed_order_cost::Number, variable_order_cost::Number, components::Pair{<:Item, <:Number}...; capacity = Inf, name = "" )
    Assembly(FixedLinearOrderCost(fixed_order_cost, variable_order_cost), components..., capacity = capacity, name = name )
end

state(::Assembly) = Float64[]
state_size(::Assembly) = 0
action_size(::Assembly)::Int = 0
print_state(::Assembly) = Pair{String, Float64}[]
print_action(::Assembly) = Pair{String, Float64}[]

function pull!(ass::Assembly, quantity::Number, issuer)
    @assert 0 == length(ass.pull_orders) "assembly received multiple orders"
    push!(ass.pull_orders, issuer => min(quantity, ass.capacity))
    nothing
end

function Base.push!(ass::Assembly, quantity, source)
    ass.pull_orders[source] = quantity
    nothing
end

function activate!(ass::Assembly, action)
    destination, quantity = first(ass.pull_orders)
    for (component, required) in ass.requirements
        pull!(component, quantity*required, ass)
    end
    nothing
end

function dispatch!(ass::Assembly)
    destination = first(filter(i -> !(i in ass.components), keys(ass.pull_orders)))
    quantity = ass.pull_orders[destination]
    for (component, required) in ass.requirements
        quantity = min(quantity, ass.pull_orders[component]/required)
    end
    for (component, required) in ass.requirements
        excess = pop!(ass.pull_orders, component) - required*quantity
        push!(component, excess, ass)
    end 
    ass.pull_orders[destination] = quantity
    push!(destination, quantity, ass)
    nothing
end

function reward!(ass::Assembly)
    cost = ass.production_cost(ass)
    empty!(ass.pull_orders)
    return -cost
end

reset!(::Assembly) = nothing

children(ass::Assembly) = ass.components

#cost functions defined in supplier.jl
function (f::FixedLinearOrderCost)(ass::Assembly) 
    q = sum(values(ass.pull_orders))
    return (q > 0)*(f.K + f.c*q)
end

(f::LinearOrderCost)(ass::Assembly) = f.c*sum(values(ass.pull_orders))

Base.show(io::IO, ass::Assembly{F}) where {F} = print(io, "Assembly($(ass.name), $F)")