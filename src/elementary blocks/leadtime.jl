mutable struct LeadTime{F, D<:Distribution}
    holding_cost::F
    onorder::Vector{Float64}
    leadtime::Int
    onorder_reset::D
    pull_orders::IdDict{Any,Float64}
end

function LeadTime(holding_cost, leadtime::Number, onorder::NumDist)
    @assert hasmethod(holding_cost, Tuple{LeadTime}) "holding cost must have a method with (::LeadTime) signature"
    doo = parametrify(onorder)
    oo = max.(0.0, rand(doo, leadtime))
    LeadTime(holding_cost, oo, Int(leadtime), doo, IdDict{Any, Float64}())
end

function LeadTime(holding_cost::Number, leadtime::Number, onorder::NumDist)
    LeadTime(LinearHoldingCost(holding_cost), Int(leadtime), onorder)
end

function LeadTime(leadtime::Number, onorder::NumDist)
    LeadTime(it-> 0.0, leadtime, onorder)
end

state(lt::LeadTime) = vec(lt.onorder)
state_size(lt::LeadTime) = lt.leadtime
print_state(lt::LeadTime) = [" on order t-$i" => oo for (i, oo) in enumerate(lt.onorder)]

function Base.push!(lt::LeadTime, quantity, source)
    lt.pull_orders[source] = quantity
    push!(lt.onorder, quantity)
    nothing
end

function dispatch!(lt::LeadTime)
    destination, quantity = only(lt.pull_orders)
    push!(destination, popfirst!(lt.onorder), lt)
    nothing
end

function reward!(lt::LeadTime)
    cost = lt.holding_cost(lt)
    empty!(lt.pull_orders)
    return -cost
end

inventory_position(lt::LeadTime) = sum(lt.onorder)
    
function reset!(lt::LeadTime)
    lt.onorder = max.(0., rand(lt.onorder_reset, lt.leadtime))
end

#Defined in item.jl
(f::LinearHoldingCost)(lt::LeadTime) = f.h*sum(lt.onorder)

Base.show(io::IO, lt::LeadTime{F,D}) where {F,D} = print(io, "LeadTime($(lt.leadtime) periods, $F)")
