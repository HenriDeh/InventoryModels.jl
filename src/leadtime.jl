mutable struct LeadTime{F, D<:Distribution, S} <: BOMElement
    holding_cost::F
    onorder::Vector{Float64}
    leadtime::Int
    onorder_reset::D
    source::S
    pull_orders::IdDict{Any, Float64}
    name::String
end

function LeadTime(holding_cost, leadtime::Number, onorder::NumDist, source; name ="")
    @assert hasmethod(holding_cost, Tuple{LeadTime}) "holding cost must have a method with (::LeadTime) signature"
    doo = parametrify(onorder)
    oo = rand(doo, leadtime)
    LeadTime(holding_cost, max.(zero(eltype(oo)), oo), Int(leadtime), doo, source, IdDict{Any, eltype(oo)}(), name)
end

function LeadTime(holding_cost::Number, leadtime::Number, onorder::NumDist, source; name ="")
    LeadTime(LinearHoldingCost(holding_cost), Int(leadtime), onorder, source, name = name)
end

function LeadTime(leadtime::Number, onorder::NumDist, source; name ="")
    lt = Int(leadtime)
    doo = parametrify(onorder)
    oo = rand(doo, lt)
    LeadTime(it->zero(eltype(oo)),max.(zero(eltype(oo)), oo), lt, doo, source, IdDict{Any, eltype(oo)}(), name)
end


state(lt::LeadTime) = vec(lt.onorder)
state_size(lt::LeadTime) = lt.leadtime
action_size(::LeadTime)::Int = 0
print_state(lt::LeadTime) = [lt.name*" on order t-$i" => oo for (i, oo) in enumerate(lt.onorder)]
print_action(::LeadTime) = Pair{String, Float64}[]

function pull!(lt::LeadTime, quantity, issuer)
    @assert 0 == length(lt.pull_orders) "lead time received multiple orders"
    push!(lt.pull_orders, issuer => quantity)
    nothing
end

function Base.push!(lt::LeadTime, quantity, source)
    push!(lt.onorder, quantity)
    nothing
end

function activate!(lt::LeadTime, ::Any...)
    pull!(lt.source, last(first(lt.pull_orders)), lt)
    nothing
end

function dispatch!(lt::LeadTime)
    destination, quantity = first(lt.pull_orders)
    push!(destination, popfirst!(lt.onorder), lt)
    nothing
end

function reward!(lt::LeadTime)
    cost = lt.holding_cost(lt)
    empty!(lt.pull_orders)
    return -cost
end
    
function reset!(lt::LeadTime)
    lt.onorder = max.(0., rand(lt.onorder_reset, lt.leadtime))
end

children(lt::LeadTime) = (lt.source,)

#Defined in item.jl
(f::LinearHoldingCost)(lt::LeadTime) = f.h*sum(lt.onorder)

Base.show(io::IO, lt::LeadTime{F,D,S}) where {F,D,S} = print(io, "LeadTime($(lt.name), $F)")
