
"""
`Inventory` represent the inventory of an inv in the BOM of an `InventorySystem`.
During the top-bottom activation, an `Inventory` receives pull orders from `Assembly`s or `Market`s.  
During the bottom-top activation, an `Inventory` resolves the pull orders by pushing quantities from its on-hand inventory to pull-order issuers.
No prioritization is considered with respect to external demand's cost penalties. Two alternatives could be considered later:
1) adding a prioritization "action" to the action space of the `inv`; 
2) creating a _recourse_ framework where the agent must decide order quantities before the demand realizes but can allocate after.
Consequently the inventory models cannot fully model environments where an inv has both external and internal demands or more than one external demand.
"""
mutable struct Inventory{OH, F}
    holding_cost::F
    onhand::OH
    capacity::Float64
    pull_orders::IdDict{Any, Float64}
    on_hand_log::Vector{Float64}
    stockout_log::Vector{Float64}
    fillrate_log::Vector{Float64}
    cost_log::Vector{Float64}
    name::String
end

function Inventory(holding_cost, onhand::State; capacity::Number = Inf, name = "inventory")
    @assert hasmethod(holding_cost, Tuple{Inventory}) "holding cost must have a method with `(::Inventory)` arguments"
    onhand.val = min(capacity, onhand.val)
    Inventory{typeof(onhand), typeof(holding_cost)}(holding_cost, onhand, Float64(capacity),  IdDict(), zeros(0), zeros(0), zeros(0), zeros(0), name)
end

Inventory(holding_cost, onhand::Union{Number, Distribution}; kwargs...) = Inventory(holding_cost, State(onhand); kwargs...)

function Inventory(holding_cost::Number, onhand::State; kwargs...)
    Inventory(LinearHoldingCost(holding_cost), onhand; kwargs...)
end

ReinforcementLearningBase.state(inv::Inventory) = [inv.onhand.val]
state_size(::Inventory) = 1
print_state(inv::Inventory) = [inv.name*" on hand" => inv.onhand.val]

function pull!(inv::Inventory, quantity::Number, issuer)
    push!(inv.pull_orders, issuer => quantity)
    return nothing
end

function Base.push!(inv::Inventory, quantity, source)
    inv.onhand.val += min(quantity, inv.capacity-inv.onhand.val)
    nothing
end

function dispatch!(inv::Inventory)
    sumorders = sum(values(inv.pull_orders))
    if sumorders != 0 
        proportion = min(one(sumorders), inv.onhand.val/sumorders)
        for (issuer, quantity) in inv.pull_orders
            push!(issuer, quantity*proportion, inv)
        end
        push!(inv.stockout_log, (1-proportion)*sumorders)
        push!(inv.fillrate_log, proportion)
        inv.onhand.val -= proportion*sumorders
    else
        push!(inv.stockout_log, 0.0)
        push!(inv.fillrate_log, 1.0)
        for (issuer, quantity) in inv.pull_orders
            push!(issuer, 0.0, inv)
        end
    end
    nothing
end

"""
    reward(inv::Inventory)

1. Resolve the pull orders by pushing quantities from its on-hand inventory to pull-order issuers with proportional distribution in case of shortage.
2. Erase pull_orders.
3. Returns a reward with respect to minus its `cost` function. 
"""
function reward!(inv::Inventory) 
    push!(inv.on_hand_log, inv.onhand.val)
    empty!(inv.pull_orders)
    cost = inv.holding_cost(inv)
    push!(inv.cost_log, cost)
    return -cost
end

"""
    reset!(inv::Inventory)

Randomizes inv's on-hand inventory with respect to its initial distribution"
"""
function ReinforcementLearningBase.reset!(inv::Inventory)
    empty!(inv.cost_log)
    empty!(inv.on_hand_log)
    empty!(inv.fillrate_log)
    empty!(inv.stockout_log)
    reset!(inv.onhand)
    inv.onhand.val = min(inv.capacity, inv.onhand.val)
    return nothing
end

inventory_position(inv::Inventory) = inv.onhand.val

"""
    LinearHoldingCost(h) 

A simple linear holding cost function with h as the cost per unit of `onhand` inventory.
"""
mutable struct LinearHoldingCost{T}
    h::T
end
(f::LinearHoldingCost)(inv::Inventory) = f.h*inv.onhand.val

Base.show(io::IO, inv::Inventory{OH, F}) where {OH,F} = print(io, "Inventory($(inv.name), $F)")