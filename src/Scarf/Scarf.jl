module Scarf

using Distributions, SpecialFunctions
export Instance, DP_sS

mutable struct Instance{T <: Real}
    holding_cost::T
    backorder_cost::T
    setup_cost::T
    production_cost::T
    lead_time::Int
    gamma::T
    backlog::Bool
    demand_forecasts::Vector{Normal{T}}
    lt_demand_forecasts::Vector{Normal{T}}
    H::Int
    s::Array{T,1}
    S::Array{T,1}
end

function Instance(h,b,K,c,CV,LT,demands, gamma = 1. ; backlog = one(CV))
    T = typeof(CV)
    dists = Normal{T}[]
    @assert b > c && b > h
    for d in demands
        push!(dists, Normal(d, CV*d))
    end
    lt_dists = Normal{T}[]
    for t in 1:(length(dists)-LT)
        mean_sum = zero(T)
        mean_var = zero(T)
        for i in 0:LT
            mean_sum += mean(dists[t+i])
            mean_var += var(dists[t+i])
        end
        push!(lt_dists, Normal(mean_sum, sqrt(mean_var)))
    end
    backlog = min(one(backlog), max(zero(backlog), backlog))
    S = fill(-Inf, length(dists))
    s = fill(-Inf, length(dists))
    Instance{T}(h,b,K,c,LT, gamma, backlog, dists,lt_dists,length(dists), S, s)
end

mutable struct Pwla{T}
    breakpoints::Array{T,1}
    range::StepRangeLen{T,T,T}
end

function Pwla(stepsize)
    T = typeof(stepsize)
    Pwla{T}(Array{T,1}(), stepsize:stepsize:stepsize)
end

Base.push!(p::Pwla, x) = push!(p.breakpoints, x)

function (pwla::Pwla)(y)
    if length(pwla.breakpoints) > 0
        return (@view pwla.breakpoints[end:-1:1])[Int(round((y - pwla.range[1])/pwla.range.step)+1)]
    else
        return zero(y)
    end
end

function production_cost(instance::Instance, q)
    if q > 0
        return instance.production_cost*q + instance.setup_cost
    else
        return zero(q)
    end
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
        ub = instance.backlog ? quantile(df, 0.99999) : y
        ξ = pwla.range.step:pwla.range.step:ub
        x = y .- ξ
        p = cdf.(df, ξ .+ ξ.step.hi/2) .- cdf.(df, ξ .- ξ.step.hi/2)
        c(x) = C(instance, x, t+1, pwla)
        return sum(c.(x) .* p) - cdf(df, y)c(zero(y))*(1-instance.backlog)
    end
end

function DP_sS(instance::Instance{T}, stepsize::T = one(T)) where T <: Real
    H = instance.H
    λ = instance.lead_time
    meandemand = max(stepsize, mean(mean.(instance.demand_forecasts)))
    critical_ratio = 1# (instance.backorder_cost-instance.holding_cost)/instance.backorder_cost
    EOQ = sqrt(2*meandemand*instance.setup_cost/(critical_ratio*instance.holding_cost))
    ub = 2*(EOQ+meandemand*λ)
    upperbound = ub + stepsize - ub%stepsize
    C_tplus1 = Pwla(stepsize)
    for t in H-λ:-1:1
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
        C_tplus1 = C_t
    end
end

end #module
