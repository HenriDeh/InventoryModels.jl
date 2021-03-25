function sl_sip(h, b, K, CV, c, μ::Vector, LT::Int = 0; lostsales = false)
    bom = BOMElement[]
    push!(bom, Supplier(K,c))
    if LT > 0
        push!(bom, LeadTime(0, LT, last(bom)))
    end
    push!(bom, Item(h, sSPolicy(), 0, last(bom)))
    push!(bom, Market(b, CVNormal{CV}, length(μ), last(bom), 0, [μ; zero(μ)], lostsales = lostsales))
    InventorySystem(length(μ), bom)
end

function assembly10(;holding_costs, fixed_costs, variable_costs, leadtimes, backorder_cost, demand_forecast, CV, initlevels = zeros(10))
    suppliers = []
    lts = []
    items = []
    assembs = []
    for i in 5:10
        sup = Supplier(fixed_costs[i], variable_costs[i])
        lt = LeadTime(leadtimes[i], 0., sup)
        item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt)
        push!(suppliers, sup)
        push!(lts, lt)
        push!(items, item)
    end
    sfitems = Iterators.Stateful(items)
    for i in 2:4
        ass = Assembly(fixed_costs[i], variable_costs[i], popfirst!(sfitems) => 1, popfirst!(sfitems) => 1)
        lt = LeadTime(holding_costs[i*2+1] + holding_costs[i*2+2], leadtimes[i], 0., ass)
        item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt)
        push!(assembs, ass)
        push!(lts, lt)
        push!(items, item)
    end
    i = 1
    ass = Assembly(fixed_costs[i], variable_costs[i], popfirst!(sfitems) => 1, popfirst!(sfitems) => 1, popfirst!(sfitems) => 1)
    lt = LeadTime(holding_costs[2] + holding_costs[3] + holding_costs[4], leadtimes[i], 0., ass)
    item = Item(holding_costs[i], sSPolicy(), initlevels[i], lt)
    push!(assembs, ass)
    push!(lts, lt)
    push!(items, item)

    market = Market(backorder_cost, CVNormal{CV}, length(demand_forecast), items[1], 0., [demand_forecast; demand_forecast])
    InventorySystem(length(demand_forecast), suppliers..., assembs..., lts..., items..., market)
end 