
"""
`Inventory` represent the inventory of an inv in the BOM of an `InventorySystem`.
During the top-bottom activation, an `Inventory` receives pull orders from `Assembly`s or `Market`s.  
During the bottom-top activation, an `Inventory` resolves the pull orders by pushing quantities from its on-hand inventory to pull-order issuers.
No prioritization is considered with respect to external demand's cost penalties. Two alternatives could be considered later:
1) adding a prioritization "action" to the action space of the `inv`; 
2) creating a _recourse_ framework where the agent must decide order quantities before the demand realizes but can allocate after.
Consequently the inventory models cannot fully model environments where an inv has both external and internal demands or more than one external demand.
"""
mutable struct Inventory{Dl<:Distribution, F}
    holding_cost::F
    onhand::Float64
    capacity::Float64
    onhand_reset::Dl
    pull_orders::IdDict{Any, Float64}
    on_hand_log::Vector{Float64}
    stockout_log::Vector{Float64}
    fillrate_log::Vector{Float64}
    cost_log::Vector{Float64}
    name::String
end

function Inventory(holding_cost, onhand::NumDist; capacity::Number = Inf, name = "inventory")
    @assert hasmethod(holding_cost, Tuple{Inventory}) "holding cost must have a method with `(::Inventory)` arguments"
    dl = parametrify(onhand)
    Inventory{typeof(dl), typeof(holding_cost)}(holding_cost, min(capacity, Float64(rand(dl))), Float64(capacity), dl,  IdDict(), zeros(0), zeros(0), zeros(0), zeros(0), name)
end

function Inventory(holding_cost::Number, onhand::NumDist; capacity::Number = Inf, name = "inventory")
    Inventory(LinearHoldingCost(holding_cost), onhand, capacity = capacity, name = name)
end

RLBase.state(inv::Inventory) = [inv.onhand]
state_size(::Inventory) = 1
print_state(inv::Inventory) = [inv.name*" on hand" => inv.onhand]

function pull!(inv::Inventory, quantity::Number, issuer)
    push!(inv.pull_orders, issuer => quantity)
    return nothing
end

function Base.push!(inv::Inventory, quantity, source)
    inv.onhand += min(quantity, inv.capacity-inv.onhand)
    nothing
end

function dispatch!(inv::Inventory)
    sumorders = sum(values(inv.pull_orders))
    if sumorders != 0 
        proportion = min(one(sumorders), inv.onhand/sumorders)
        for (issuer, quantity) in inv.pull_orders
            push!(issuer, quantity*proportion, inv)
        end
        push!(inv.stockout_log, (1-proportion)*sumorders)
        push!(inv.fillrate_log, proportion)
        inv.onhand -= proportion*sumorders
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
    push!(inv.on_hand_log, inv.onhand)
    empty!(inv.pull_orders)
    cost = inv.holding_cost(inv)
    push!(inv.cost_log, cost)
    return -cost
end

"""
    reset!(inv::Inventory)

Randomizes inv's on-hand inventory with respect to its initial distribution"
"""
function RLBase.reset!(inv::Inventory)
    empty!(inv.cost_log)
    empty!(inv.on_hand_log)
    empty!(inv.fillrate_log)
    empty!(inv.stockout_log)
    inv.onhand = min(inv.capacity, rand(inv.onhand_reset))
    return nothing
end

inventory_position(inv::Inventory) = inv.onhand

"""
    LinearHoldingCost(h) 

A simple linear holding cost function with h as the cost per unit of `onhand` inventory.
"""
mutable struct LinearHoldingCost{T}
    h::T
end
(f::LinearHoldingCost)(inv::Inventory) = f.h*inv.onhand

Base.show(io::IO, inv::Inventory{Dl, F}) where {Dl,F} = print(io, "Inventory($(inv.name), $F)")