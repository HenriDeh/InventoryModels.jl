@testset "market.jl" begin
    @test_throws AssertionError market = Market(LinearStockoutCost(5), Normal, 4, 0, (fill(Uniform(5,15),4),))
    market = Market(5, Normal, 4, 0, (fill(10,20), fill(0.0,20)))
    @test state_size(market) == 9
    @test state(market) == [0; fill(10., 4); fill(0., 4)]
    @test InventoryModels.inventory_position(market) == 0
    @test InventoryModels.demand!(market) == 10
    push!(market, 6, [])
    @test InventoryModels.reward!(market) == -4*5
    @test state(market) == [4; fill(10., 4); fill(0., 4)]
    @test InventoryModels.inventory_position(market) == -4
    @test InventoryModels.demand!(market) == 14
    push!(market, 14,[])
    @test state(market) == [0; fill(10., 4); fill(0., 4)]
    reset!(market)
    @test state(market) == [0; fill(10., 4); fill(0., 4)]

    market = Market(5, Normal, 4, Normal(10,0), ([20,40,60,40], fill(0.,4)))
    @test state_size(market) == 9
    @test state(market) == [10; [20,40,60,40]; fill(0.,4)]
    @test InventoryModels.inventory_position(market) == -10
    @test InventoryModels.demand!(market) == 30
    push!(market, 6, [])
    @test InventoryModels.reward!(market) == -24*5
    @test state(market) == [24; [40,60,40,0]; fill(0.,4)]
    @test InventoryModels.inventory_position(market) == -24
    reset!(market)
    @test state(market) == [10; [20,40,60,40]; fill(0.,4)]
end