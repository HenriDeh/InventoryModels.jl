module InventoryModels

using Distributions, DataStructures, MacroTools, Base.Iterators
const NumDist = Union{Number, Distribution}
const State = Union{NumDist, AbstractVector{<:NumDist}}

abstract type BOMElement end

include("utils.jl")
export observe, observation_size, action_size, activate!, replenish!, pull!, reward!, reset!, dispatch!
include("item.jl")
export Item, LinearHoldingCost
include("policies.jl")
export sSPolicy, RQPolicy, QPolicy, BQPolicy
include("supplier.jl")
export Supplier, LinearOrderCost, FixedLinearOrderCost
include("leadtime.jl")
export LeadTime
include("market.jl")
export Market, LinearStockoutCost
include("assembly.jl")
export Assembly
include("cvnormal.jl")
export CVNormal
include("inventory_system.jl")
export InventorySystem


#=
include("Scarf.jl")

import DataStructures: Queue, enqueue!, dequeue!, Deque
import MacroTools.@forward
import Distributions.params
@reexport using .Scarf
export BOMElement, ActionableElement, Inventory, Supplier, ProductInventory, Market, InventoryProblem
export observation_size, action_size, observe, reset!, test_reset!, isdone, action_squashing_function, test_Scarf_policy
export fixed_linear_cost, linear_cost, linear_holding_cost, linear_stockout_cost, expected_holding_cost, expected_stockout_cost, CVNormal
export DynamicEnvi
"""
A custom distributions useful for the initial states. It is simply a wrapper into a single Multivariate Distribution to be used instead of calling rand(<:Distribution, ::Int).
"""

include("utils.jl")

abstract type BOMElement{T<:Real} end
abstract type ActionableElement{T<:Real} <: BOMElement{T} end

"""Inventory"""

mutable struct Inventory{T <: Real, F, S, R <: Union{T, UnivariateDistribution}, TR <: Union{T, UnivariateDistribution}} <: BOMElement{T}
    holding_cost::F
    level::T
    minimum_level::T
    source::S
    reset_level::R
    test_reset_level::TR
end

function Inventory( holding_cost,
                    source,
                    reset_level,
                    minimum_level = 0;
                    test_reset_level::Union{Real, UnivariateDistribution} = reset_level
                    )

    @assert !isempty(methods(holding_cost)) "holding_cost must be callable"
    level = max(minimum_level, reset_level isa UnivariateDistribution ? rand(reset_level) : reset_level)
    T = typeof(level)
    if reset_level isa Real
        reset_level = T(reset_level)
    end
    if test_reset_level isa Real
        test_reset_level = T(test_reset_level)
    end

    Inventory(holding_cost, level, T(minimum_level), source,reset_level, test_reset_level)
end


observe(inv::Inventory) = inv.level
observation_size(inv::Inventory) = 1

function reset!(inv::Inventory)
    inv.level = max(inv.minimum_level, inv.reset_level isa UnivariateDistribution ? rand(inv.reset_level) : inv.reset_level)
    return nothing
end
function test_reset!(inv::Inventory)
    inv.level = max(inv.minimum_level, inv.test_reset_level isa UnivariateDistribution ? rand(inv.test_reset_level) : inv.test_reset_level)
    return nothing
end

function (inv::Inventory{T})(q) where T
    @assert q >= 0
    inv.level += popfirst!(inv.source.orders) - q
    position = max(zero(inv.level), inv.level) + sum(inv.source.orders)
    return inv.holding_cost(position)
end

"""ProductInventory"""

mutable struct ProductInventory{T, F, S, R <: Union{T, UnivariateDistribution}, TR <: Union{T, UnivariateDistribution}} <: BOMElement{T}
    holding_cost::F
    level::T
    source::S
    minimum_level::T
    reset_level::R
    test_reset_level::TR
end

function ProductInventory(  holding_cost,
                            source,
                            reset_level,
                            minimum_level = -Inf;
                            test_reset_level = reset_level
                            )
    @assert !isempty(methods(holding_cost)) "holding_cost must be callable"
    level = max(minimum_level, reset_level isa UnivariateDistribution ? rand(reset_level) : reset_level)

    ProductInventory(holding_cost, level, source, minimum_level, reset_level, test_reset_level)
end

observe(p::ProductInventory) = p.level
observation_size(p::ProductInventory) = 1

function reset!(p::ProductInventory)
    p.level = max(p.minimum_level, p.reset_level isa UnivariateDistribution ? rand(p.reset_level) : p.reset_level)
    return nothing
end
function test_reset!(p::ProductInventory)
    p.level = max(p.minimum_level, p.test_reset_level isa UnivariateDistribution ? rand(p.test_reset_level) : p.test_reset_level)
    return nothing
end

function (inv::ProductInventory)(q)
    @assert q >= 0
    inv.level += popfirst!(inv.source.orders) - q
    return inv.level
end

"""Supplier"""

mutable struct Supplier{T <: Real, F, R <: Union{T, UnivariateDistribution}, TR <: Union{T, UnivariateDistribution}} <: ActionableElement{T}
    order_cost::F
    lead_time::Int
    orders::Vector{T}
    reset_orders::Vector{R}
    test_reset_orders::Vector{TR}
end

function Supplier(  order_cost,
                    reset_orders=zeros(0);
                    test_reset_orders = reset_orders)
    @assert length(reset_orders) == length(test_reset_orders)
    @assert !isempty(methods(order_cost)) "order_cost must be callable"
    order_queue = eltype(reset_orders) <: Distribution ? rand.(reset_orders) : reset_orders
    T = eltype(order_queue)
    if !(eltype(reset_orders) <: Distribution)
        reset_orders = T.(reset_orders)
    end
    if !(eltype(test_reset_orders) <: Distribution)
        test_reset_orders = T.(test_reset_orders)
    end
    lead_time = length(reset_orders)
    Supplier(order_cost, lead_time, order_queue, reset_orders, test_reset_orders)
end

observe(sup::Supplier) = sup.orders
observation_size(sup::Supplier) = sup.lead_time
function reset!(sup::Supplier)
    sup.orders = max.(zero(eltype(sup.orders)), eltype(sup.reset_orders) <: Distribution ? rand.(sup.reset_orders) : sup.reset_orders)
    return nothing
end
function test_reset!(sup::Supplier)
    sup.orders = max.(zero(eltype(sup.orders)), eltype(sup.test_reset_orders) <: Distribution ? rand.(sup.test_reset_orders) : sup.test_reset_orders)
    return nothing
end

function (sup::Supplier)(q)
    q = max(zero(q), q)
    push!(sup.orders, q)
    return sup.order_cost(q)
end

"""Assembly"""
#TODO relu the action

mutable struct Assembly{T, F, R <: Union{T, UnivariateDistribution}, TR <: Union{T, UnivariateDistribution}} <: ActionableElement{T}
    order_cost::F
    components::Vector{Tuple{Int, Inventory{T}}}
    lead_time::Int
    orders::Vector{T}
    reset_orders::Vector{R}
    test_reset_orders::Vector{TR}
end

function Assembly(  order_cost,
                    components,
                    reset_orders;
                    test_reset_orders = reset_orders
                    ) where T <: Real

    @assert length(reset_orders) == length(test_reset_orders)
    @assert !isempty(methods(order_cost)) "order_cost must be callable"
    @assert !isempty(components) "Assembly must have at least one component"
    order_queue = eltype(reset_orders) <: Distribution ? rand.(reset_orders) : reset_orders
    lead_time = length(reset_orders)
    Assembly(order_cost, components, lead_time, holding_cost, order_queue, reset_orders, test_reset_orders)
end

observe(a::Assembly) = collect(a.orders)
observation_size(a::Assembly) = a.lead_time
function reset!(a::Assembly)
    p.orders = max.(zero(eltype(a.orders)), eltype(a.reset_orders) <: Distribution ? rand.(a.reset_orders) : a.reset_orders)
    return nothing
end
function test_reset!(a::Assembly)
    p.orders = max.(zero(eltype(a.orders)), eltype(a.test_reset_orders) <: Distribution ? rand.(a.test_reset_orders) : a.test_reset_orders)
    return nothing
end

function (a::Assembly{T})(q) where T
    q = max(zero(q), q)
    component_holding_costs = zero(T)
    for (n, comp) in a.components
        q = min(q, div(comp.level, n))
    end
    for (n, comp) in a.components
        component_holding_costs += comp(q*n)
    end
    push!(a.orders, q)
    return a.order_cost(q) + component_holding_costs
end

"""Market"""

mutable struct Market{T<:Real, D <: UnivariateDistribution, F, P<:ProductInventory{T}, R, TR} <: BOMElement{T}
    stockout_cost::F
    product::P
    demand_forecasts::Vector{D}
    backlog::Bool
    horizon::Int
    t::Int
    reset_forecasts::Vector{R}
    test_reset_forecasts::Vector{TR}
    expected_reward::Bool
end

function Market(stockout_cost,
                product,
                err_dist,
                backlog::Bool,
                reset_forecasts;
                test_reset_forecasts = reset_forecasts,
                expected_reward = false,
                horizon = length(reset_forecasts))
    @assert 0 <= horizon <= length(reset_forecasts)
    @assert !isempty(methods(stockout_cost)) "stockout_cost must be callable"
    demand_forecast = eltype(reset_forecasts) <: err_dist ? reset_forecasts : [err_dist(rand.(tup)...) for tup in reset_forecasts]
    if !backlog
        product.level = max(zero(product.level), product.level)
        product.minimum_level = zero(product.level)
    end
    Market(stockout_cost, product, demand_forecast, backlog, horizon, 1, reset_forecasts, test_reset_forecasts, expected_reward)
end

function observe(m::Market{T}) where T
    horizon = min(m.t + m.horizon - 1, lastindex(m.demand_forecasts))
    state = zeros(T, observation_size(m))
    i = 1
    for dist in @view m.demand_forecasts[m.t:horizon]
        for p in params(dist)
            state[i] = p
            i += 1
        end
    end
    return state
end
observation_size(m::Market) = m.horizon*length(params(first(m.demand_forecasts)))

function reset!(m::Market)
    m.t = 1
    err_dist = eltype(m.demand_forecasts)
    m.demand_forecasts = eltype(m.reset_forecasts) <: Distribution ? m.reset_forecasts : [err_dist(rand.(tup)...) for tup in m.reset_forecasts]
    return nothing
end

function test_reset!(m::Market)
    m.t = 1
    D = eltype(m.demand_forecasts)
    m.demand_forecasts = eltype(m.test_reset_forecasts) <: Distribution ? m.test_reset_forecasts : [D(rand.(tup)...) for tup in m.test_reset_forecasts]
    return nothing
end

function (m::Market{T})() where T
    demand = max(zero(T), rand(m.demand_forecasts[m.t]))
    if m.expected_reward
        holding_cost = m.product.holding_cost(m.product.level+m.product.source.orders[1] , m.demand_forecasts[m.t])
        stockout_cost = m.stockout_cost(m.product.level+m.product.source.orders[1], m.demand_forecasts[m.t])
        m.product(demand)
    else
        m.product(demand)
        holding_cost = m.product.holding_cost(m.product.level)
        stockout_cost = m.stockout_cost(m.product.level)
    end
    m.t += 1
    if !m.backlog && m.product.level < 0
        m.product.level = zero(T)
    end
    return holding_cost + stockout_cost
end


"""InventoryProblem"""

mutable struct InventoryProblem{T <: Real, A <: Tuple, B <: Tuple, M <: Market{T}}
    BOM::B
    actionables::A
    market::M
end

function InventoryProblem(BOM::Vector{BOMElement{T}}) where T
    actionables = ActionableElement{T}[]
    markets = Market[]
    for el in BOM
        if el isa ActionableElement
            push!(actionables, el)
        elseif el isa Market
            push!(markets, el)
        end
    end
    @assert length(markets) == 1 "InventoryProblem must have one and only one market in the BOM"
    InventoryProblem(tuple(BOM...), tuple(actionables...), first(markets))
end

function observe(ip::InventoryProblem{T}) where T
    reduce(vcat, observe.(ip.BOM))
end

function observation_size(ip::InventoryProblem)
    sum(observation_size.(ip.BOM))
end

action_size(ip::InventoryProblem) = length(ip.actionables)

reset!(ip::InventoryProblem) = reset!.(ip.BOM)

test_reset!(ip::InventoryProblem) = test_reset!.(ip.BOM)

function (ip::InventoryProblem{T})(action) where T
    reward = zero(T)
    for (i, element) in enumerate(ip.actionables)
        reward -= element(action[i])
    end
    reward -= ip.market()
end

isdone(ip::InventoryProblem) = ip.market.t > ip.market.horizon

action_squashing_function(ip::InventoryProblem) = x -> max(zero(x), x)

Base.eltype(ip::InventoryProblem{T}) where T = T

include("policy_tests.jl")
include("DynamicEnvi.jl")=#
end # of module
