mutable struct Market{D<:Distribution, F, B <: State, FC <: Tuple}
    stockout_cost::F 
    demand_dist::Type{D}
    backorders::B
    lostsales::Bool
    horizon::Int
    forecast_parameters::FC
    last_demand::Float64
    backorder_log::Vector{Float64}
    fillrate_log::Vector{Float64}
    cost_log::Vector{Float64}
    name::String
end

"""
```
    Market(stockout_cost, demand_distribution::Type{<:Distribution}, horizon::Int, backorders::State, forecast_parameters::Tuple; lostsales::Bool = false, name="market")
```
Creates a market module. `stockout_cost` is a callable that takes a (::Market) argument and returns the stockout costs for the period. 
Providing a scalar will result in a `LinearStockoutCost(stockout_cost)`.
`demand_distribution` is the type of the distribution of the demand. 
`horizon` is the number of periods of forecast returned in the state.
`backorders` is a (scalar) `State` of the backorder level.
`forecast_parameters` is a `NTuple` of `State`, each defines the state of the parameters of `demand_distribution`.
"""
function Market(stockout_cost, demand_distribution::Type{<:Distribution}, horizon::Int, backorders::State, forecast_parameters::Tuple; lostsales::Bool = false, name="market")
    @assert hasmethod(stockout_cost, Tuple{Market}) "stockout cost must have a method with `(::Market)` signature"
    @assert length(forecast_parameters) == length(params(demand_distribution())) "Please provide a reset distribution for each parameter of $demand_distribution"

    if !all(forecast_parameters) do p
            p isa State        
        end
        fp = ((State(p) for p in forecast_parameters)...,)
    else
        fp = forecast_parameters
    end

    Market{demand_distribution, typeof(stockout_cost), typeof(backorders), typeof(fp)}(
        stockout_cost, demand_distribution, backorders, lostsales, horizon, fp, 0., zeros(0), zeros(0), zeros(0), name)
end

function Market(stockout_cost, demand_distribution::Type{<:Distribution}, horizon::Int, backorders::Union{Number, Distribution}, forecast_parameters::Tuple; kwargs...)
    Market(stockout_cost, demand_distribution, horizon, State(backorders), forecast_parameters; kwargs...)
end

function Market(stockout_cost::Number, demand_distribution::Type{<:Distribution}, horizon::Int, backorders::Union{Number, Distribution}, forecast_parameters::Tuple; kwargs...)
    Market(LinearStockoutCost(stockout_cost), demand_distribution, horizon, backorders, forecast_parameters; kwargs...)
end

function ReinforcementLearningBase.state(ma::Market)
    if ma.lostsales
        mapreduce(p -> p.val[1:ma.horizon], vcat, ma.forecast_parameters)
    else
        [ma.backorders.val; mapreduce(p -> p.val[1:ma.horizon], vcat, ma.forecast_parameters)]
    end
end
state_size(ma::Market) = (1-ma.lostsales)+ma.horizon*length(ma.forecast_parameters)
function print_state(ma::Market; forecast = true)
    if ! forecast
        return "$(ma.name) backorders" => ma.backorders.val
    end
    s = ["$(ma.name) backorders" => ma.backorders.val]
    forecast_params = state(ma)[2:end]
    idx = 1
    for j in eachindex(ma.forecast_parameters)
        for i in 0:horizon-1
            push!(s, "$(ma.name) demand(parameter $j) t+$(i)" => forecast_params[idx])
            idx += 1
        end
    end
    return s
end

function demand!(ma::Market)
    params = (first(p.val) for p in ma.forecast_parameters)
    demand_distribution = ma.demand_dist(params...)
    demand = rand(demand_distribution)
    ma.last_demand = max(zero(demand), demand)
    return ma.backorders.val + ma.last_demand
end

function Base.push!(ma::Market, quantity, source)  
    ma.backorders.val += ma.last_demand 
    ma.backorders.val -= min(quantity, ma.backorders.val)
    return nothing
end

function reward!(ma::Market)
    for param_state in ma.forecast_parameters
        popfirst!(param_state.val)
        if length(param_state.val) < ma.horizon
            push!(param_state.val, 0.)
        end
    end

    cost = ma.stockout_cost(ma)
    push!(ma.backorder_log, ma.backorders.val)
    push!(ma.fillrate_log, max(0, (1-ma.backorders.val/ma.last_demand)))
    push!(ma.cost_log, cost)
    ma.backorders.val *= (1 - ma.lostsales)
    return -cost
end

function ReinforcementLearningBase.reset!(ma::Market)
    reset!(ma.backorders)
    for param_state in ma.forecast_parameters
        reset!(param_state)
    end
    empty!(ma.backorder_log)
    empty!(ma.cost_log)
    empty!(ma.fillrate_log)
    return nothing
end

inventory_position(ma::Market) = -ma.backorders.val

mutable struct LinearStockoutCost{T}
    b::T
end
(f::LinearStockoutCost)(ma::Market) = f.b*ma.backorders.val

Base.show(io::IO, market::Market{D, F, B, FC}) where {D, F, B, FC} = print(io, "Market($D, LS:$(market.lostsales))")