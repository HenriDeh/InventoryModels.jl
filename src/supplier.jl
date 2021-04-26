"""
    Supplier(order_cost, onorder::NumDist, leadtime::Int = 0, capacity::number = Inf; name = "")
"""
mutable struct Supplier{F} <: BOMElement
    order_cost::F
    capacity::Float64
    pull_orders::IdDict{Any, Float64}
    name::String
end

function Supplier(order_cost; capacity::Number = Inf, name = "")
    @assert hasmethod(order_cost, Tuple{Supplier}) "order cost must have a method with `(::Supplier) signature`"
    Supplier(order_cost, Float64(capacity), IdDict{Any,Float64}(), name)
end

function Supplier(fixed_order_cost::Number, variable_order_cost::Number; capacity::Number = Inf, name = "") 
    Supplier(FixedLinearOrderCost(fixed_order_cost,variable_order_cost), capacity = capacity, name = name)
end

state(::Supplier) = Float64[]
state_size(::Supplier) = 0
action_size(::Supplier)::Int = 0
print_state(::Supplier) = Pair{String, Float64}[]
print_action(::Supplier) = Pair{String, Float64}[]

function pull!(sup::Supplier, quantity::Number, issuer)
    @assert 0 == length(sup.pull_orders) "supplier received multiple orders"
    push!(sup.pull_orders, issuer => min(quantity, sup.capacity))
    nothing
end
Base.push!(::Supplier, quantity, source) = nothing

activate!(sup::Supplier, action) = nothing

function dispatch!(sup::Supplier)
    destination, quantity = first(sup.pull_orders)
    push!(destination, quantity, sup)
    nothing
end

function reward!(sup::Supplier)
    cost = sup.order_cost(sup)
    empty!(sup.pull_orders)
    return -cost
end

function reset!(::Supplier)
    nothing
end

children(sup::Supplier) = ()

mutable struct FixedLinearOrderCost{T1,T2}
    K::T1
    c::T2
end
function (f::FixedLinearOrderCost)(sup::Supplier) 
    q = sum(values(sup.pull_orders))
    return (q > 0)*(f.K + f.c*q)
end

mutable struct LinearOrderCost{T2}
    c::T2
end
(f::LinearOrderCost)(sup::Supplier) = f.c*sum(values(sup.pull_orders))

Base.show(io::IO, sup::Supplier{F}) where {F} = print(io, "Supplier($(sup.name), $F)")