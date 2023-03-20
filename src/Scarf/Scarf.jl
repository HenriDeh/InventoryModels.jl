module Scarf

export Instance, DP_sS
using Distributions, SpecialFunctions, StaticArrays

struct Instance{T <: Real, D <: Distribution, D2 <: Distribution}
    holding_cost::T
    backorder_cost::T
    setup_cost::T
    production_cost::T
    lead_time::Int
    gamma::T
    demand_forecasts::Vector{D}
    lt_demand_forecasts::Vector{D2}
    H::Int
    s::Array{T,1}
    S::Array{T,1}
end

function Instance(h,b,K,c,LT, forecast_parameters, gamma = 1. ; distribution_type = Normal)
    T = Float64
    @assert b > c && b > h
    dists = [distribution_type(fp...) for fp in forecast_parameters]
    if LT == 0
        lt_dists = dists
    else
        lt_dists = [foldl(convolve, dists[t:t+LT]) for t in 1:(length(dists)-LT)]
    end
    S = fill(-Inf, length(dists))
    s = fill(-Inf, length(dists))
    Instance{T, eltype(dists), eltype(lt_dists)}(h,b,K,c,LT, gamma, dists,lt_dists,length(dists), S, s)
end

mutable struct Pwla{T, S <: StepRangeLen}
    breakpoints::Vector{T}
    range::S
end

function Pwla(s)
    stepsize = Float64(s)
    Pwla(Float64[], stepsize:stepsize:stepsize)
end

Base.push!(p::Pwla, x) = push!(p.breakpoints, x)

function (pwla::Pwla)(y)
    if length(pwla.breakpoints) > 0
        return (@view pwla.breakpoints[end:-1:1])[Int(round((y - pwla.range[1])/step(pwla.range))+1)]
    else
        return zero(y)
    end
end

function production_cost(instance::Instance, q)
    return (q > 0) * (instance.production_cost*q + instance.setup_cost)
end

function L(instance::Instance, y, t::Int)
    h = instance.holding_cost
    b = instance.backorder_cost
    μ = mean(instance.lt_demand_forecasts[t])
    v = var(instance.lt_demand_forecasts[t])
    e = MathConstants.e
    π = MathConstants.pi
    fh = zero(y)
    fb = zero(y)
    if y >= 0
        fh = (((e^(-((y - μ)^2)/2v) -e^(-(μ^2)/2v))*sqrt(v))/(sqrt(2π))) + 1//2*(y-μ)*(erf((y-μ)/(sqrt(2)*sqrt(v))) + erf(μ/(sqrt(2)*sqrt(v))))
        fh *= h
        fb = ((e^(-((y - μ)^2)/2v))*v + sqrt(π/2) * (μ - y) * sqrt(v) * erfc((y-μ)/(sqrt(2)*sqrt(v))))/(sqrt(2π)*sqrt(v))
        fb *= b
    else
        fb = (e^(-(μ^2)/2v)*v + sqrt(π/2) * (μ - y) * sqrt(v) * (1 + erf(μ/(sqrt(2)*sqrt(v)))))/(sqrt(2π)*sqrt(v))
        fb *= b
    end
    return fb + fh
end

function G(instance::Instance, y, t::Int)
    instance.production_cost*y + L(instance, y, t)
end

function C(instance::Instance, x, t::Int, pwla::Pwla)
    S = instance.S[t]
    s = instance.s[t]
    q = x <= s ? S - x : 0.0
    return production_cost(instance, q) + L(instance, x + q, t) + instance.gamma*pwla(x + q)
end

function expected_future_cost(instance::Instance, y, t::Int, pwla::Pwla)
    if t >= instance.H-instance.lead_time
        return zero(y)
    else
        df = instance.demand_forecasts[t]
        ub = quantile(df, 0.999)
        ξ = step(pwla.range):step(pwla.range):ub
        x = y .- ξ
        p = cdf.(df, ξ .+ step(ξ)/2) .- cdf.(df, ξ .- step(ξ)/2)
        c(x) = C(instance, x, t+1, pwla)
        return sum(c.(x) .* p)
    end
end

function DP_sS(instance::Instance{T}, stepsize::Real = 1) where T <: Real
    H = instance.H
    λ = instance.lead_time
    maxdemand = max(stepsize, maximum(mean.(instance.demand_forecasts)))
    critical_ratio = 1
    EOQ = sqrt(2*maxdemand*instance.setup_cost/(critical_ratio*instance.holding_cost))
    ub = 2*(EOQ+maxdemand*λ)
    upperbound = ub + stepsize - ub%stepsize
    C_tplus1 = Pwla(stepsize) 
    start = H - λ 
    for t in start:-1:1
        C_t = Pwla(stepsize)
        descending = true
        y = upperbound
        EFC = expected_future_cost(instance, y, t, C_tplus1)
        g = G(instance, y, t) + EFC
        push!(C_t, EFC)
        instance.S[t] = y
        ming = g
        while g <= ming + instance.setup_cost || descending
            y -= stepsize
            EFC = expected_future_cost(instance, y, t, C_tplus1)
            push!(C_t, EFC)
            g = G(instance, y, t) + EFC
            if g < ming
                ming = g
                instance.S[t] = y
            elseif descending
                descending = false
            end
        end
        instance.s[t] = y
        C_t.range = y:stepsize:upperbound
        #=
        if C_t(upperbound) < C_t(y) 
            @warn "Upperbound is too low at iteration $t: $(C_t(upperbound)) vs$(C_t(y))" maxlog = 1
        end=#
        C_tplus1 = C_t
    end
    return C_tplus1
end

end #module
