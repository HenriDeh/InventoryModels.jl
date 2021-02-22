
#creates a problem instance compatible with the Scarf.jl module
function Instance(envi::InventoryProblem)
    envi = deepcopy(envi)
    @assert length(envi.BOM) == 3
    @assert action_size(envi) == 1
    sup = envi.BOM[1]
    @assert sup isa Supplier
    product = envi.BOM[2]
    @assert product isa ProductInventory
    market = envi.market
    h = product.holding_cost.h
    b = market.stockout_cost.b
    K  = sup.order_cost.K
    c = sup.order_cost.c
    LT = sup.lead_time
    dem = mean.(market.demand_forecasts)
    CV = std(first(market.demand_forecasts))/mean(first(market.demand_forecasts))
    return Scarf.Instance(h, b, K, c, CV, LT, dem, market.backlog)
end

#Monte Carlo test of a (S,s) policy. Only works on single-level SIP
function test_Scarf_policy(envi::InventoryProblem, S, s, n = 10000)
    envi = deepcopy(envi)
    @assert length(envi.BOM) == 3
    @assert action_size(envi) == 1
    @assert envi.BOM[1] isa Supplier
    @assert envi.BOM[2] isa ProductInventory
    totReward = zero(eltype(envi))
    test_reset!(envi)
    for i in 1:n
        reward = zero(eltype(envi))
        t = 1
        while !isdone(envi)
            y = observe(envi.BOM[2]) + sum(observe(envi.BOM[1]))
            q = y < s[t] ? S[t] - y : zero(eltype(envi))
            reward += envi(q)
            t += 1
        end
        totReward += reward
        test_reset!(envi)
    end
    totReward /= n
    #println("Optimal policy cost: $totReward")
    return totReward
end
