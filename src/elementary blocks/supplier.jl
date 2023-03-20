"""
    Supplier(order_cost, onorder::NumDist, leadtime::Int = 0, capacity::number = Inf; name = "")
"""
mutable struct Supplier{F,L <:LeadTime}
    order_cost::F
    capacity::Float64
    leadtime::L
    pull_orders::IdDict{Any, Float64}
    batchsize_log::Vector{Float64}
    cost_log::Vector{Float64}
    name::String
end

function Supplier(order_cost; leadtime = leadtime::LeadTime = LeadTime(0, zeros(0)), capacity::Number = Inf, name = "supplier")
    @assert hasmethod(order_cost, Tuple{Supplier}) "order cost must have a method with `(::Supplier) signature`"
    Supplier(order_cost, Float64(capacity), leadtime, IdDict{Any,Float64}(), zeros(0), zeros(0), name)
end

function Supplier(fixed_order_cost::Number, variable_order_cost::Number; leadtime::LeadTime = LeadTime(0, zeros(0)), capacity::Number = Inf, name = "supplier") 
    Supplier(FixedLinearOrderCost(fixed_order_cost,variable_order_cost), leadtime = leadtime, capacity = capacity, name = name)
end

ReinforcementLearningBase.state(s::Supplier) = state(s.leadtime)
state_size(s::Supplier) = state_size(s.leadtime)
print_state(s::Supplier) = print_state(s.leadtime)

function pull!(sup::Supplier, quantity::Number, issuer) #add leadtime
    @assert 0 == length(sup.pull_orders) "supplier received multiple orders"
    push!(sup.pull_orders, issuer => min(quantity, sup.capacity))
    nothing
end

function dispatch!(sup::Supplier)
    destination, quantity = only(sup.pull_orders)
    push!(sup.batchsize_log, quantity)
    push!(sup.leadtime, quantity, destination)
    dispatch!(sup.leadtime)
    nothing
end

function reward!(sup::Supplier)
    cost = sup.order_cost(sup)
    push!(sup.cost_log, cost)
    empty!(sup.pull_orders)
    return -cost + reward!(sup.leadtime)
end

inventory_position(sup::Supplier) = inventory_position(sup.leadtime)

function ReinforcementLearningBase.reset!(s::Supplier)
    empty!(s.cost_log)
    empty!(s.batchsize_log)
    reset!(s.leadtime)
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

Base.show(io::IO, sup::Supplier{F}) where {F} = print(io, "Supplier($(sup.name), $F, $(sup.leadtime.leadtime))")