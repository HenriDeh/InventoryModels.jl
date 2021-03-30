mutable struct expected_holding_cost{T} <: AbstractCost
    h::T
end

function (f::expected_holding_cost)(y, demand_dist::Union{CVNormal,Normal})
    μ = mean(demand_dist)
    σ = std(demand_dist)
    σ == 0 && return linear_holding_cost(f.h)(y-μ)
    h = f.h
    v = σ^2
    e = MathConstants.e
    π = MathConstants.pi
    fh = zero(y)
    if y >= 0
        fh = (((e^(-((y - μ)^2)/2v) -e^(-(μ^2)/2v))*sqrt(v))/(sqrt(2π))) + 1//2*(y-μ)*(erf((y-μ)/(sqrt(2)*sqrt(v))) + erf(μ/(sqrt(2)*sqrt(v))))
        fh *= h
    end
    return fh
end

mutable struct expected_stockout_cost{T} <: AbstractCost
    b::T
end

function (f::expected_stockout_cost)(y, demand_dist::Union{CVNormal,Normal})
    μ = mean(demand_dist)
    σ = std(demand_dist)
    σ == 0 && return linear_stockout_cost(f.h)(y-μ)
    b = f.b
    v = σ^2
    e = MathConstants.e
    π = MathConstants.pi
    fb = zero(y)
    if y >= 0
        fb = ((e^(-((y - μ)^2)/2v))*v + sqrt(π/2) * (μ - y) * sqrt(v) * erfc((y-μ)/(sqrt(2)*sqrt(v))))/(sqrt(2π)*sqrt(v))
        fb *= b
    else
        fb = (e^(-(μ^2)/2v)*v + sqrt(π/2) * (μ - y) * sqrt(v) * (1 + erf(μ/(sqrt(2)*sqrt(v)))))/(sqrt(2π)*sqrt(v))
        fb *= b
    end
    return fb
end