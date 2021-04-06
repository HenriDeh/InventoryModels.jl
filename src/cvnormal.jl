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

cv(d::CVNormal{CV}) where CV = CV

#Base.show(io::IO, n::CVNormal) = show(n.normal)
