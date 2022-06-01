export CVNormal, BoundedWienerProcess

struct CVNormal{CV,T} <: ContinuousUnivariateDistribution
    normal::Normal{T}
    CVNormal{CV}(n::Normal{T}) where {CV, T} = new{CV,T}(n)
end
CVNormal{CV}(μ::Number) where {CV} = CVNormal{CV}(Normal(μ,CV*μ))
CVNormal{CV}() where {CV} = CVNormal{CV}(0)

MacroTools.@forward CVNormal.normal Distributions.mean, Base.rand, Distributions.sampler, Distributions.pdf, Distributions.logpdf, Distributions.cdf, Distributions.quantile, Distributions.minimum,
    Distributions.maximum, Distributions.insupport, Distributions.var, Distributions.std, Distributions.modes, Distributions.mode, Distributions.skewness, Distributions.kurtosis,
    Distributions.entropy, Distributions.mgf, Distributions.cf, Base.eltype
Distributions.params(d::CVNormal) = mean(d)
Base.rand(i::InventoryModels.CVNormal, v::Vararg{Int64, N} where N) = rand(i.normal, v...)

cv(d::CVNormal{CV}) where CV = CV
cv(d::Type{CVNormal{CV}}) where CV = CV

#Base.show(io::IO, n::CVNormal) = show(n.normal)

####BoundedWienerProcess
mutable struct BoundedWienerProcess{T, D <: ContinuousUnivariateDistribution} <: ContinuousUnivariateDistribution
    x::T
    d::D
    lb::T
    ub::T
end

BoundedWienerProcess(d::Distribution, lb, ub) = BoundedWienerProcess(rand(Uniform(lb,ub)), d, eltype(d)(lb), eltype(d)(ub))

function Base.rand(bw::BoundedWienerProcess)
    delta = rand(bw.d)
    bw.x = max(bw.lb, min(bw.ub, bw.x + delta))
    bw.x
end

reset!(b::BoundedWienerProcess) = b.x = rand(Uniform(b.lb,b.ub))
