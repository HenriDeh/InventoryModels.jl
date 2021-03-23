
"""
`Item` represent the inventory of an item in the BOM of an `InventorySystem`.
During the top-bottom activation, an `Item` receives pull orders from `Assembly`s or `Market`s.  
During the bottom-top activation, an `Item` resolves the pull orders by pushing quantities from its on-hand inventory to pull-order issuers.
No prioritization is considered with respect to external demand's cost penalties. Two alternatives could be considered later:
1) adding a prioritization "action" to the action space of the `item`; 
2) creating a _recourse_ framework where the agent must decide order quantities before the demand realizes but can allocate after.
Consequently the inventory models cannot fully model environments where an item has both external and internal demands or more than one external demand.
"""
mutable struct Item{Dl<:Distribution, F, S<:Tuple, P} <: BOMElement
    holding_cost::F
    policy::P
    onhand::Float64
    capacity::Float64
    sources::S
    onhand_reset::Dl
    pull_orders::IdDict{Any, Float64}
    name::String
end

function Item(holding_cost, policy, onhand::NumDist, sources...; capacity::Number = Inf, name = "")
    @assert hasmethod(holding_cost, Tuple{Item}) "holding cost must have a method with `(::Item)` arguments"
    dl = parametrify(onhand)
    s = tuple(sources...)
    Item{typeof(dl), typeof(holding_cost), typeof(s), typeof(policy)}(
        holding_cost, policy, Float64(max(zero(eltype(dl)), rand(dl))), Float64(capacity), s, dl,  IdDict(), name)
end

observe(item::Item) = [item.onhand]
observation_size(::Item) = 1
action_size(item::Item)::Int = length(item.sources)*action_size(item.policy)

"""
    pull!(item::Item, Pair{Any, Number})

Adds a pull order to `item`'s pull orders' list. 
Pull orders are arbitrarily resolved by the `item` to allocate insufficient on-hand inventory proportionnaly to the order sizes. 
"""
function pull!(item::Item, quantity::Number, issuer)
    push!(item.pull_orders, issuer => quantity)
    return nothing
end

"""
    Base.push!(item::Item, replenishment::Number)

Add `replenishment` to the onhand inventory of `item`. Excess quantity with respect to the capacity is wasted.
"""
function Base.push!(item::Item, quantity, source)
    item.onhand += min(quantity, item.capacity-item.onhand)
    nothing
end

"""
    activate!(item::Item, action)

Send pull order to all sources according to the policy parameters given by `action` and returns nothing because `Item` does not have an action space. 
"""
function activate!(item::Item, action)
    actions = Iterators.partition(action, action_size(item.policy))
    for (source, polparams) in zip(item.sources, actions)
       pull!(source, item.policy(item, polparams...), item) 
    end
    return nothing
end

function dispatch!(item::Item)
    sumorders = sum(values(item.pull_orders))
    if sumorders != 0
        proportion =  min(one(sumorders), item.onhand/sumorders)
        for (issuer, quantity) in item.pull_orders
            push!(issuer, quantity*proportion, item)
        end
        item.onhand -= proportion*sumorders
    end
    nothing
end

"""
    reward(item::Item)

1. Resolve the pull orders by pushing quantities from its on-hand inventory to pull-order issuers with proportional distribution in case of shortage.
2. Erase pull_orders.
3. Returns a reward with respect to minus its `cost` function. 
"""
function reward!(item::Item) 
    empty!(item.pull_orders)
    -item.holding_cost(item)
end

"""
    reset!(item::Item)

Randomizes item's on-hand inventory with respect to its initial distribution"
"""
function reset!(item::Item)
    item.onhand = max(zero(item.onhand), rand(item.onhand_reset))
    return nothing
end

function inventory_position(item::Item)
    item.onhand + sum(Float64[sum(source.onorder) for source in item.sources if source isa LeadTime])
end

children(item::Item) = item.sources

"""
    LinearHoldingCost(h) 

A simple linear holding cost function with h as the cost per unit of `onhand` inventory.
"""
mutable struct LinearHoldingCost{T}
    h::T
end
(f::LinearHoldingCost)(item::Item) = f.h*item.onhand

Base.show(io::IO, item::Item{Dl, F, S, P}) where {Dl,F,S,P} = print("Item{", Base.typename(F), ",", Base.typename(P),"}")