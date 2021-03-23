mutable struct Market{D<:Distribution, L<:Union{Bool, AbstractFloat}, F, S, Df, Db <: Distribution} <:BOMElement
    stockout_cost::F 
    demand_dist::Type{D}
    backorder::Float64
    lostsales::L
    horizon::Int
    forecasts::Vector{Float64}
    source::S
    backorder_reset::Db
    forecast_reset::Df
    name::String
end

function Market(stockout_cost, demand_distribution::Type{<:Distribution}, horizon::Int, source, backorder_reset::NumDist, forecast_reset::State...; lostsales = false, name="")
    @assert hasmethod(stockout_cost, Tuple{Market}) "stockout cost must have a method with `(::Market)` signature"
    @assert all(x -> x isa State, forecast_reset)
    @assert length(forecast_reset) == length(params(demand_distribution()))
    @assert 0 <= lostsales <= 1
    bd = parametrify(backorder_reset)
    frd = Iterators.Stateful.(cycle.(parametrify.(forecast_reset)))
    forecasts = Float64[rand(param) for _ in 1:horizon for param in popfirst!.(frd)]

    Market{demand_distribution, typeof(lostsales), typeof(stockout_cost), typeof(source), typeof(frd), typeof(bd)}(
        stockout_cost, demand_distribution, Float64(rand(bd)), lostsales, horizon, forecasts, source, bd, tuple(frd...), name)
end

observe(ma::Market) = ma.lostsales ? ma.forecasts : [ma.backorder; ma.forecasts]
observation_size(ma::Market) = (ma.lostsales != 1) + ma.horizon*length(ma.forecast_reset)
action_size(::Market)::Int = 0

function pull!(::Market, ::Any...)
    nothing
end

function Base.push!(ma::Market, quantity, source)
    ma.backorder -= min(quantity, ma.backorder)
    return nothing
end

function activate!(ma::Market, action)
    param = ma.forecasts[1:length(ma.forecast_reset)]
    demand = rand(ma.demand_dist(param...))
    ma.backorder += max(zero(demand), demand)
    pull!(ma.source, ma.backorder, ma)
    nothing
end

dispatch!(::Market) = nothing

function reward!(ma::Market)
    deleteat!(ma.forecasts, 1:length(ma.forecast_reset))
    push!(ma.forecasts, rand.(popfirst!.(ma.forecast_reset))...)
    cost = ma.stockout_cost(ma)
    ma.backorder *= (1 - ma.lostsales)
    return -cost
end

function reset!(ma::Market)
    ma.forecasts = Float64[rand(param) for _ in 1:ma.horizon for param in popfirst!.(ma.forecast_reset)]
    ma.backorder = rand(ma.backorder_reset)
    return nothing
end

children(ma::Market) = (ma.source,)

mutable struct LinearStockoutCost{T}
    b::T
end
(f::LinearStockoutCost)(ma::Market) = f.b*ma.backorder

Base.show(io::IO, market::Market{D,F,S,Df,Db}) where {D,F,S,Df,Db} = print("Market{$D,",Base.typename(F),"}")