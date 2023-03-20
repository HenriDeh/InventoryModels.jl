export CVNormal, BoundedWienerProcess, SingleItemMMFE, exp_multiplicative_mmfe, MinMaxUniformDemand, SigmaLogNormal

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
Distributions.convolve(d1::CVNormal, d2::CVNormal) = convolve(d1.normal, d2.normal)
Distributions.convolve(d1::Normal, d2::CVNormal) = convolve(d1, d2.normal)
Distributions.convolve(d1::CVNormal, d2::Normal) = convolve(d1.normal, d2)

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
    new_x = bw.x + delta
    excess = max(0, new_x - bw.ub)
    miss = max(0, bw.lb - new_x)
    bw.x = new_x + miss - excess
    bw.x
end

reset!(b::BoundedWienerProcess) = b.x = rand(Uniform(b.lb,b.ub))

###MinMaxUniformDemand
mutable struct MinMaxUniformDemand{T} <: ContinuousUnivariateDistribution
    bound_dist::Uniform{T}
    demand_dist::Uniform{T}
    minrange::T
end

function MinMaxUniformDemand(lower::T, upper::T, minrange) where T <: Number 
    bdist = Uniform(lower, upper)
    _bounds = minmax(rand(bdist,2)...)
    _bounds2 = (_bounds[1], min(bdist.b, max(_bounds[2], _bounds[1] + minrange)))
    bounds = (min(_bounds2[1], _bounds2[2] - minrange), _bounds2[2])
    ddist = Uniform(bounds...)
    MinMaxUniformDemand(bdist, ddist, eltype(bdist)(minrange))
end

Base.rand(m::MinMaxUniformDemand) = rand(m.demand_dist)

function reset!(m::MinMaxUniformDemand) 
    bdist = m.bound_dist
    _bounds = minmax(rand(bdist,2)...)
    _bounds2 = (_bounds[1], min(bdist.b, max(_bounds[2], _bounds[1] + minrange)))
    bounds = (min(_bounds2[1], bound2[2] - minrange), _bounds2[2])
    m.demand_dist = Uniform(bounds...)
end

###Martingale Model of Forecast Evolution
"""
    SingleItemMMFE(env, f)

Wraps a single item single stage environment to update its forecast according to f!, where f! is a function that takes a forecast vector and updates it.
"""
struct SingleItemMMFE{E,F,B}
    env::E
    f!::F
    T::Int
    bom::B
end

function SingleItemMMFE(env, f)
    SingleItemMMFE(env, f, env.T, env.bom)    
end

MacroTools.@forward SingleItemMMFE.env state, state_size, action_size, is_terminated, reward, print_state, print_action

function (mmfe::SingleItemMMFE)(action)
    r = mmfe.env(action)
    mmfe.f!(mmfe.env.bom[1].market.forecasts)
    return r
end

"""
    exp_multiplicative_mmfe(start_var, decay)

Return a function that takes a forecast vector as input and applies a multiplicative mmfe 
transformation to it.
The update factors are randomly selected according to a lognormal distribution. `start_var` 
is the variance of the normal distribution at time 1, subsequent variances are exponentialy 
decayed by a factor of `decay`.
"""
function exp_multiplicative_mmfe(start_var, decay)
    function f(forecast) 
        vars = [start_var*decay^(t-1) for t in 1:length(forecast)]
        stds = sqrt.(vars)
        means = - 0.5 * vars
        norms = MvLogNormal(means, stds)
        Rs = rand(norms)
        forecast .*= Rs
    end
end



