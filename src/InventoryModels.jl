module InventoryModels

using Requires
using Distributions, DataStructures, MacroTools, Reexport, Base.Iterators
@reexport using ReinforcementLearningBase: reset!, state, RLBase, ReinforcementLearningBase, is_terminated, AbstractEnv, reward
import IterTools

const NumDist = Union{Number, Distribution}
#const State = Union{NumDist, AbstractVector{<:NumDist}}

abstract type AbstractItem end

include("state.jl")
include("elementary blocks/inventory.jl")
export Inventory, LinearHoldingCost
include("elementary blocks/leadtime.jl")
export LeadTime
include("elementary blocks/policies.jl")
export sSPolicy, RQPolicy, QPolicy, BQPolicy
include("elementary blocks/supplier.jl")
export Supplier, LinearOrderCost, FixedLinearOrderCost
include("elementary blocks/market.jl")
export Market, LinearStockoutCost
include("elementary blocks/assembly.jl")
export Assembly
include("items/endproduct.jl")
export EndProduct
include("items/item.jl")
export Item
include("items/depot.jl")
export Depot
include("demand_distributions.jl")
export CVNormal, cv
include("constraints.jl")
#export RessourceConstraint
include("inventory_system.jl")
export InventorySystem, state_size, action_size, print_state, print_action
include("zoo.jl")
export sl_sip
include("Scarf/Scarf.jl")
export Scarf
export ISLogger
include("logger.jl")

#stateless objects are unchanged when reseted
RLBase.reset!(::Any) = nothing

#=export dashboard, draw_graph
include("dashboard/dashboard.jl")=#
end