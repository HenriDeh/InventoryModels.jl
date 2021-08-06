module InventoryModels

using Requires
using Distributions, DataStructures, MacroTools, Base.Iterators, Reexport

function __innit__()
    @require GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a" begin 
        include("dashboard/dashboard.jl")
        export dashboard
    end
end

const NumDist = Union{Number, Distribution}
const State = Union{NumDist, AbstractVector{<:NumDist}}

abstract type AbstractItem end

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
include("cvnormal.jl")
export CVNormal, cv
include("constraints.jl")
export RessourceConstraint
include("inventory_system.jl")
export InventorySystem, state, state_size, action_size, reward, reset!, is_terminated, print_state, print_action
include("utils.jl")
export test_policy
include("zoo.jl")
export sl_sip
include("Scarf/Scarf.jl")
export Scarf
include("Scarf/interface.jl")
export ISLogger
include("logger.jl")
end