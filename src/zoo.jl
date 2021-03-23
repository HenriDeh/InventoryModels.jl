function sl_sip(h, b, K, CV, c, μ::Vector, LT::Int = 0; lostsales = false)
    bom = BOMElement[]
    push!(bom, Supplier(FixedLinearOrderCost(K,c)))
    if LT > 0
        push!(bom, LeadTime(0, LT, last(bom)))
    end
    push!(bom, Item(LinearHoldingCost(h), sSPolicy(), 0, last(bom)))
    push!(bom, Market(LinearStockoutCost(b), CVNormal{CV}, length(μ), last(bom), 0, [μ; zero(μ)], lostsales = lostsales))
    InventorySystem(length(μ), bom)
end