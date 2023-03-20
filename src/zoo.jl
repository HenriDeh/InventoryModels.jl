function sl_sip(h, b, K, c, μ::Vector, start_inventory, LT::Int = 0; lostsales = false, horizon = length(μ), policy = sSPolicy(), periods = horizon, d_type)
    item = EndProduct(
        Market(b, d_type, horizon, 0, μ, lostsales = lostsales),
        Inventory(h, start_inventory),
        Supplier(K,c, leadtime = LeadTime(LT, 0)),
        policy = policy
    )
    InventorySystem(periods, [item])
end

function sl_sip(h, b, K, c, μ::Distribution, start_inventory, LT::Int = 0; lostsales = false, policy = sSPolicy(), horizon::Int, periods::Int, d_type)
    item = EndProduct(
        Market(b, d_type, horizon, 0, μ, lostsales = lostsales),
        Inventory(h, start_inventory),
        Supplier(K,c, leadtime = LeadTime(LT, 0)),
        policy = policy
    )
    InventorySystem(periods, [item])
end