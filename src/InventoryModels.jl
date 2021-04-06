module InventoryModels

using Distributions, DataStructures, MacroTools, Base.Iterators, Reexport
include("Scarf/Scarf.jl")
@reexport using .Scarf
const NumDist = Union{Number, Distribution}
const State = Union{NumDist, AbstractVector{<:NumDist}}

abstract type BOMElement end

export test_policy
export Item, LinearHoldingCost
export sSPolicy, RQPolicy, QPolicy, BQPolicy
export Supplier, LinearOrderCost, FixedLinearOrderCost
export LeadTime
export Market, LinearStockoutCost
export Assembly
export CVNormal, cv
export InventorySystem, state, state_size, action_size, reward, reset!, is_terminated
export sl_sip
include("item.jl")
include("policies.jl")
include("supplier.jl")
include("leadtime.jl")
include("market.jl")
include("assembly.jl")
include("cvnormal.jl")
include("inventory_system.jl")
include("utils.jl")
include("zoo.jl")
include("Scarf/interface.jl")
end