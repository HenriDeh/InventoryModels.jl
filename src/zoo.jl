function sl_sip(h, b, K, CV, c, μ::Vector, start_inventory, LT::Int = 0; lostsales = false, pad = true, policy = sSPolicy())
    item = EndProduct(
        Market(b, CVNormal{CV}, length(μ), 0, [μ; pad ? zero(μ) : μ], lostsales = lostsales),
        Inventory(h, start_inventory),
        Supplier(K,c, leadtime = LeadTime(LT, 0)),
        policy = policy
    )
    InventorySystem(length(μ), [item])
end

function sl_sip(h, b, K, CV, c, μ::Distribution, horizon, start_inventory, LT::Int = 0; lostsales = false, policy = sSPolicy())
    item = EndProduct(
        Market(b, CVNormal{CV}, horizon, 0, μ, lostsales = lostsales),
        Inventory(h, start_inventory),
        Supplier(K,c, leadtime = LeadTime(LT, 0)),
        policy = policy
    )
    InventorySystem(horizon, [item])
end

"""
InventoryModels.assembly10(holding_costs = ones(10), fixed_costs = 100*ones(10), variable_costs = zeros(10), leadtimes=ones(10), backorder_cost = 10, demand_forecast = [20,40,60,40,20,40,60], CV = 0.25)

order capacities are decentralized, this does not implements the "shared ressources" generalization of Thevenin et al.
"""
#=
function assembly10(;holding_costs, fixed_costs, variable_costs, leadtimes, backorder_cost, demand_forecast, CV, order_capacities = fill(Inf, 10), inventory_capacities = fill(Inf, 10), initlevels = zeros(10))
    suppliers = []
    lts = []
    items = []
    assembs = []
    for i in 5:10
        sup = Supplier(fixed_costs[i], variable_costs[i], capacity = order_capacities[i])
        lt = LeadTime(leadtimes[i], 0., sup)
        item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
        push!(suppliers, sup)
        push!(lts, lt)
        push!(items, item)
    end
    sfitems = Iterators.Stateful(items)
    for i in 2:4
        ass = Assembly(fixed_costs[i], variable_costs[i], popfirst!(sfitems) => 1, popfirst!(sfitems) => 1, capacity = order_capacities[i])
        lt = LeadTime(leadtimes[i], 0., ass)
        item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
        push!(assembs, ass)
        push!(lts, lt)
        push!(items, item)
    end
    i = 1
    ass = Assembly(fixed_costs[i], variable_costs[i], popfirst!(sfitems) => 1, popfirst!(sfitems) => 1, popfirst!(sfitems) => 1, capacity = order_capacities[i])
    lt = LeadTime(leadtimes[i], 0., ass)
    item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
    push!(assembs, ass)
    push!(lts, lt)
    push!(items, item)

    market = Market(backorder_cost, CVNormal{CV}, length(demand_forecast), items[1], 0., [demand_forecast; demand_forecast])
    InventorySystem(length(demand_forecast), suppliers..., assembs..., lts..., items..., market)
end 


function general10(;holding_costs, fixed_costs, variable_costs, leadtimes, backorder_costs, demand_forecasts, CVs, order_capacities = fill(Inf, 10), inventory_capacities = fill(Inf, 10), initlevels = zeros(10))
    suppliers = []
    lts = []
    items = []
    assembs = []
    markets = []
    for i in 8:10
        sup = Supplier(fixed_costs[i], variable_costs[i], capacity = order_capacities[i])
        lt = LeadTime(leadtimes[i], 0., sup)
        item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
        push!(suppliers, sup)
        push!(lts, lt)
        push!(items, item)
    end
    for (j, i) in enumerate(5:6)
        ass = Assembly(fixed_costs[i], variable_costs[i], items[j] => 1, items[j+1] => 1, capacity = order_capacities[i])
        lt = LeadTime(leadtimes[i], 0., ass)
        item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
        push!(assembs, ass)
        push!(lts, lt)
        push!(items, item)
    end
    i = 7
    ass = Assembly(fixed_costs[i], variable_costs[i], items[3] => 1, capacity = order_capacities[i])
    lt = LeadTime(leadtimes[i], 0., ass)
    item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
    push!(assembs, ass)
    push!(lts, lt)
    push!(items, item)
    i = 1
    ass = Assembly(fixed_costs[i], variable_costs[i], items[4] => 1, capacity = order_capacities[i])
    lt = LeadTime(leadtimes[i], 0., ass)
    item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
    push!(assembs, ass)
    push!(lts, lt)
    push!(items, item)
    for i in 2:3
        ass = Assembly(fixed_costs[i], variable_costs[i], items[i+2] => 1, items[i+3] => 1, capacity = order_capacities[i])
        lt = LeadTime(leadtimes[i], 0., ass)
        item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
        push!(assembs, ass)
        push!(lts, lt)
        push!(items, item)
    end
    i = 4
    ass = Assembly(fixed_costs[i], variable_costs[i], items[6] => 1, capacity = order_capacities[i])
    lt = LeadTime(leadtimes[i], 0., ass)
    item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt, capacity = inventory_capacities[i])
    push!(assembs, ass)
    push!(lts, lt)
    push!(items, item)
    for i in 1:4
        df = demand_forecasts[i]
        push!(markets, Market(backorder_costs[i], CVNormal{CVs[i]}, length(df), items[i+6], 0., [df; df]))
    end
    InventorySystem(minimum(length.(demand_forecasts)), suppliers..., lts..., assembs..., items..., markets...)
end
=#
