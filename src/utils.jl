struct CVNormal{T} <: ContinuousUnivariateDistribution
    normal::Normal{T}
end

function CVNormal{T}(μ, CV) where T
    n=Normal{T}(μ, CV*μ)
    CVNormal{T}(n)
end

function CVNormal(μ, CV)
    n=Normal(μ, CV*μ)
    CVNormal(n)
end

@forward CVNormal.normal Distributions.mean, Base.rand, Distributions.sampler, Distributions.pdf, Distributions.logpdf, Distributions.cdf, Distributions.quantile, Distributions.minimum,
    Distributions.maximum, Distributions.insupport, Distributions.var, Distributions.std, Distributions.modes, Distributions.mode, Distributions.skewness, Distributions.kurtosis,
    Distributions.entropy, Distributions.mgf, Distributions.cf, Base.eltype
Distributions.params(d::CVNormal) = mean(d)

Base.show(n::CVNormal) = print(typeof(n),"(",params(n.normal),")")

struct linear_holding_cost{T}
    h::T
end
(f::linear_holding_cost)(y) = f.h*max(zero(y), y)

struct linear_stockout_cost{T}
    b::T
end
(f::linear_stockout_cost)(y) = - f.b*min(zero(y), y)

struct fixed_linear_cost{T1,T2}
    K::T1
    c::T2
end
(f::fixed_linear_cost)(q) = q <= 0 ? zero(q) : f.K + f.c*q

linear_cost(c) = fixed_linear_cost(zero(c), c)

struct expected_holding_cost{T}
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

struct expected_stockout_cost{T}
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

function Base.sum(q::Queue) where T
    s = zero(eltype(q))
    for e in q
        s += e
    end
    return s
end
