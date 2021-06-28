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
    warmup::Int
    t::Int
    name::String
end

function Market(stockout_cost, demand_distribution::Type{<:Distribution}, horizon::Int, backorder_reset::NumDist, forecast_reset::State...; lostsales = false, name="market", warmup = 0)
    @assert hasmethod(stockout_cost, Tuple{Market}) "stockout cost must have a method with `(::Market)` signature"
    @assert all(x -> x isa State, forecast_reset)
    @assert length(forecast_reset) == length(params(demand_distribution())) "Please provide a reset distribution for each parameter of $demand_distribution"
    @assert 0 <= lostsales <= 1
    bd = parametrify(backorder_reset)
    frd = Iterators.Stateful.(cycle.(parametrify.(forecast_reset)))
    forecasts = Float64[rand(param) for _ in 1:horizon for param in popfirst!.(frd)]

    Market{demand_distribution, typeof(lostsales), typeof(stockout_cost), typeof(frd), typeof(bd)}(
        stockout_cost, demand_distribution, Float64(rand(bd)), lostsales, horizon, forecasts, 0.0, bd, tuple(frd...), warmup, 1, name)
end

function Market(stockout_cost::Number, demand_distribution::Type{<:Distribution}, horizon::Int, backorder_reset::NumDist, forecast_reset::State...; lostsales = false, name="market", warmup = 0)
    Market(LinearStockoutCost(stockout_cost), demand_distribution, horizon, backorder_reset, forecast_reset..., lostsales = lostsales, name = name, warmup = warmup)
end

state(ma::Market) = ma.lostsales ? ma.forecasts : [ma.backorder; ma.forecasts]
state_size(ma::Market) = (ma.lostsales != 1) + ma.horizon*length(ma.forecast_reset)
function print_state(ma::Market)
    n_param = length(ma.forecasts) ÷ ma.horizon
    forecasts = ["$(ma.name) demand($j) t+$(i-1)" => p for (i,pars) in enumerate(partition(ma.forecasts, n_param)) for (j,p) in enumerate(pars)]
    return ma.lostsales ? forecasts : ["$(ma.name) backorder" => ma.backorder ; forecasts]
end

function demand!(ma::Market)
    if ma.t-1 < ma.warmup
        ma.last_demand = zero(ma.last_demand)
    else
        param = ma.forecasts[1:length(ma.forecast_reset)]
        demand = rand(ma.demand_dist(param...))
        ma.last_demand = max(zero(demand), demand)
    end
    return ma.backorder + ma.last_demand
end

function Base.push!(ma::Market, quantity, source)  
    ma.backorder += ma.last_demand 
    ma.backorder -= min(quantity, ma.backorder)
    return nothing
end

function reward!(ma::Market)
    if ma.t-1 >= ma.warmup
        deleteat!(ma.forecasts, 1:length(ma.forecast_reset))
        push!(ma.forecasts, rand.(popfirst!.(ma.forecast_reset))...)
    end
    cost = ma.stockout_cost(ma)
    ma.backorder *= (1 - ma.lostsales)
    ma.t += 1
    return -cost
end

function reset!(ma::Market)
    for fr in ma.forecast_reset
        Iterators.reset!(fr, fr.itr)
    end
    ma.forecasts = Float64[rand(param) for _ in 1:ma.horizon for param in popfirst!.(ma.forecast_reset)]
    ma.backorder = rand(ma.backorder_reset)
    ma.t = 1
    return nothing
end

inventory_position(ma::Market) = -ma.backorder

mutable struct LinearStockoutCost{T}
    b::T
end
(f::LinearStockoutCost)(ma::Market) = f.b*ma.backorder

Base.show(io::IO, market::Market{D,F,Df,Db}) where {D,F,Df,Db} = print(io, "Market($D, LS:$(market.lostsales))")