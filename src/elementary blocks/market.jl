mutable struct Market{D<:Distribution, L<:Union{Bool, AbstractFloat}, F, Df, Db <: Distribution}
    stockout_cost::F 
    demand_dist::Type{D}
    backorder::Float64
    lostsales::L
    horizon::Int
    forecasts::Vector{Float64}
    last_demand::Float64
    backorder_reset::Db
    forecast_reset::Df
    backorder_log::Vector{Float64}
    fillrate_log::Vector{Float64}
    cost_log::Vector{Float64}
    name::String
end

function Market(stockout_cost, demand_distribution::Type{<:Distribution}, horizon::Int, backorder_reset::NumDist, forecast_reset::State...; lostsales::Bool = false, name="market")
    @assert hasmethod(stockout_cost, Tuple{Market}) "stockout cost must have a method with `(::Market)` signature"
    @assert all(x -> x isa State, forecast_reset)
    @assert length(forecast_reset) == length(params(demand_distribution())) "Please provide a reset distribution for each parameter of $demand_distribution"
    bd = parametrify(backorder_reset)
    frd = Iterators.Stateful.(cycle.(parametrify.(forecast_reset)))
    forecasts = Float64[rand(param) for _ in 1:horizon for param in popfirst!.(frd)]

    Market{demand_distribution, typeof(lostsales), typeof(stockout_cost), typeof(frd), typeof(bd)}(
        stockout_cost, demand_distribution, Float64(rand(bd)), lostsales, horizon, forecasts, 0.0, bd, tuple(frd...), zeros(0), zeros(0), zeros(0), name)
end

function Market(stockout_cost::Number, demand_distribution::Type{<:Distribution}, horizon::Int, backorder_reset::NumDist, forecast_reset::State...; lostsales = false, name="market")
    Market(LinearStockoutCost(stockout_cost), demand_distribution, horizon, backorder_reset, forecast_reset..., lostsales = lostsales, name = name)
end

RLBase.state(ma::Market) = [ma.backorder; ma.forecasts]
state_size(ma::Market) = 1+ma.horizon*length(ma.forecast_reset)
function print_state(ma::Market)
    n_param = length(ma.forecasts) ÷ ma.horizon
    forecasts = ["$(ma.name) demand($j) t+$(i-1)" => p for (i,pars) in enumerate(partition(ma.forecasts, n_param)) for (j,p) in enumerate(pars)]
    if !forecast 
        empty!(forecasts) 
    end
    return ma.lostsales ? forecasts : ["$(ma.name) backorder" => ma.backorder ; forecasts]
end

function demand!(ma::Market)
    param = ma.forecasts[1:length(ma.forecast_reset)]
    demand = rand(ma.demand_dist(param...))
    ma.last_demand = max(zero(demand), demand)
    return ma.backorder + ma.last_demand
end

function Base.push!(ma::Market, quantity, source)  
    ma.backorder += ma.last_demand 
    ma.backorder -= min(quantity, ma.backorder)
    return nothing
end

function reward!(ma::Market)
    deleteat!(ma.forecasts, 1:length(ma.forecast_reset))
    push!(ma.forecasts, rand.(popfirst!.(ma.forecast_reset))...)
    cost = ma.stockout_cost(ma)
    push!(ma.backorder_log, ma.backorder)
    push!(ma.fillrate_log, max(0, (1-ma.backorder/ma.last_demand)))
    push!(ma.cost_log, cost)
    ma.backorder *= (1 - ma.lostsales)
    return -cost
end

function reset!(ma::Market)
    for fr in ma.forecast_reset
        Iterators.reset!(fr, fr.itr)
    end
    ma.forecasts = Float64[rand(param) for _ in 1:ma.horizon for param in popfirst!.(ma.forecast_reset)]
    ma.backorder = rand(ma.backorder_reset)
    empty!(ma.backorder_log)
    empty!(ma.cost_log)
    empty!(ma.fillrate_log)
    return nothing
end


inventory_position(ma::Market) = -ma.backorder

mutable struct LinearStockoutCost{T}
    b::T
end
(f::LinearStockoutCost)(ma::Market) = f.b*ma.backorder

Base.show(io::IO, market::Market{D,F,Df,Db}) where {D,F,Df,Db} = print(io, "Market($D, LS:$(market.lostsales))")