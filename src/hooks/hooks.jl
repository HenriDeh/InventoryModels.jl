export PreActStage, PreConsStage, PreDispatchStage, PreRewardStage

abstract type AbstractHook end
(ah::AbstractHook)(args...) = nothing

#hook call stages
struct PreActStage end
const PREACTSTAGE = PreActStage()

struct PreConsStage end
const PRECONSSTAGE = PreConsStage()

struct PreDispatchStage end
const PREDISPATCHSTAGE = PreDispatchStage()

struct PreRewardStage end
const PREREWARDSTAGE = PreRewardStage()

#% of demand met on time
mutable struct BetaServiceLevelHook{M<:Market} <: AbstractHook
    market::M
    log::Vector{Float64}
end

BetaServiceLevelHook(market::Market) = BetaServiceLevelHook(market, Float64[])

function (sl::BetaServiceLevelHook)(::PreConsStage, args...)
    push!(sl.log, sl.market.last_demand)
end

function (sl::BetaServiceLevelHook)(::PreRewardStage, args...)
    sl.log[end] = 1 - sl.market.backorder/sl.log[end]
end



#generate demand (lastdemand)
#demand = bo + lastdemand
#