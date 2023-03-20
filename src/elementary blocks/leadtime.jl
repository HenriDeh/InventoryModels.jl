mutable struct LeadTime{F, OO <: State}
    holding_cost::F
    onorder::OO
    leadtime::Int
    pull_orders::IdDict{Any,Float64}
    cost_log::Vector{Float64}
end

function LeadTime(holding_cost, leadtime::Number, onorder::State)
    @assert hasmethod(holding_cost, Tuple{LeadTime}) "holding cost must have a method with (::LeadTime) signature"
    @assert length(onorder.val) == leadtime
    LeadTime(holding_cost, onorder, Int(leadtime), IdDict{Any, Float64}(), zeros(0))
end

function LeadTime(holding_cost::Number, leadtime::Number, onorder::State)
    LeadTime(LinearHoldingCost(holding_cost), Int(leadtime), onorder)
end

LeadTime(holding_cost, leadtime, onorder::Union{Distribution, Vector{<:Union{Number, Distribution}}}) = LeadTime(holding_cost, leadtime, State(onorder))

function LeadTime(leadtime::Number, onorder)
    LeadTime(it-> 0.0, leadtime, onorder)
end


ReinforcementLearningBase.state(lt::LeadTime) = lt.onorder.val
state_size(lt::LeadTime) = lt.leadtime
print_state(lt::LeadTime) = [" on order t+$i" => oo for (i, oo) in enumerate(lt.onorder.val)]

function Base.push!(lt::LeadTime, quantity, source)
    lt.pull_orders[source] = quantity
    push!(lt.onorder.val, quantity)
    nothing
end

function dispatch!(lt::LeadTime)
    destination, quantity = only(lt.pull_orders)
    push!(destination, popfirst!(lt.onorder.val), lt)
    nothing
end

function reward!(lt::LeadTime)
    cost = lt.holding_cost(lt)
    push!(lt.cost_log, cost)
    empty!(lt.pull_orders)
    return -cost
end

inventory_position(lt::LeadTime) = sum(lt.onorder.val)
    
function ReinforcementLearningBase.reset!(lt::LeadTime)
    empty!(lt.cost_log)
    reset!(lt.onorder)
    lt.onorder.val = max.(0., lt.onorder.val)
end

#Defined in item.jl
(f::LinearHoldingCost)(lt::LeadTime) = f.h*sum(lt.onorder.val)

Base.show(io::IO, lt::LeadTime{F,OO}) where {F,OO} = print(io, "LeadTime($(lt.leadtime) periods, $F)")
