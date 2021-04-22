@testset "market.jl" begin
    sup = Supplier(FixedLinearOrderCost(100,10))
    item = Item(LinearHoldingCost(3), sSPolicy(), 5, sup)
    @test_throws AssertionError market = Market(LinearStockoutCost(5), Normal, 10, item, 0, Uniform(5,15))
    market = Market(LinearStockoutCost(5), Normal, 4, item, 0, 10, 0.1)
    @test state(market) == [0, 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
    InventoryModels.activate!(market, [])
    demand = market.last_demand
    @test first(item.pull_orders) == (market => demand + market.backorder)
    InventoryModels.activate!(item, [item.policy(item,[0, 0])])
    InventoryModels.activate!(sup,[])
    InventoryModels.dispatch!(sup)
    InventoryModels.dispatch!(item)
    InventoryModels.dispatch!(market)
    @test InventoryModels.reward!(sup) == 0
    @test InventoryModels.reward!(item) == 0
    @test InventoryModels.reward!(market) == -5*(demand-5)
    @test state(market) == [(demand-5), 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
    @test state(item) == [0]
    @test state(sup) == []
    reset!(market)
    @test state(market) == [0, 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
    market = Market(LinearStockoutCost(5), Normal, 4, item, 0, Uniform(10,20), 0.1)
    @test state(market) != [0, 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
    @test peek.(market.forecast_reset) == (Uniform(10,20), Dirac(0.1))
    market = Market(LinearStockoutCost(5), Normal, 4, item, Uniform(-10,0), 10, 0.1)
    @test state(market) != [0, 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
    reset!(sup)
    reset!(item)
    market2 = Market(LinearStockoutCost(5), CVNormal{0.4}, 2, item, Uniform(-10,0), [20,40,60,40])
    @test state(market2)[2:end] == [20,40]
    backorder = market2.backorder
    InventoryModels.activate!(market2, [])
    demand = market2.last_demand
    @test first(item.pull_orders) == (market2 => demand + backorder)
    @assert InventoryModels.inventory_position(item) == item.onhand - backorder
    InventoryModels.activate!(item, [0])
    InventoryModels.activate!(sup,[])
    InventoryModels.dispatch!(sup)
    InventoryModels.dispatch!(item)
    @assert market2.backorder == backorder - 5 + demand 
    InventoryModels.dispatch!(market2)
    @test InventoryModels.reward!(sup) == 0
    @test InventoryModels.reward!(item) == 0
    @test -5*(market2.backorder) == InventoryModels.reward!(market2)
    reset!(market2)
    @test state(market2)[2:end] == [20,40]
end