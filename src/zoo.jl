function sl_sip(h, b, K, CV, c, μ::Vector, start_inventory, LT::Int = 0; lostsales = false, horizon = length(μ), policy = sSPolicy(), periods = horizon)
    item = EndProduct(
        Market(b, CVNormal{CV}, horizon, 0, (μ,), lostsales = lostsales),
        Inventory(h, State(start_inventory)),
        Supplier(K,c, leadtime = LeadTime(LT, State(fill(0., LT)))),
        policy = policy
    )
    InventorySystem(periods, [item])
end

function sl_sip(h, b, K, CV, c, μ::Distribution, start_inventory, LT::Int = 0; lostsales = false, policy = sSPolicy(), horizon::Int, periods::Int, infinite::Bool = true)
    item = EndProduct(
        Market(b, CVNormal{CV}, horizon, State(0), (fill(μ, periods + horizon*infinite),), lostsales = lostsales),
        Inventory(h, State(start_inventory)),
        Supplier(K,c, leadtime = LeadTime(LT, State(fill(0., LT)))),
        policy = policy
    )
    InventorySystem(periods, [item])
end