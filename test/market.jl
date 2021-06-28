@testset "market.jl" begin
    @test_throws AssertionError market = Market(LinearStockoutCost(5), Normal, 4, 0, Uniform(5,15))
    market = Market(5, Normal, 4, 0, 10, 0.0)
    @test state_size(market) == 9
    @test state(market) == [0, 10, 0.0, 10, 0.0, 10, 0.0, 10, 0.0]
    @test InventoryModels.inventory_position(market) == 0
    @test InventoryModels.demand!(market) == 10
    push!(market, 6, [])
    @test InventoryModels.reward!(market) == -4*5
    @test state(market) == [4, 10, 0.0, 10, 0.0, 10, 0.0, 10, 0.0]
    @test InventoryModels.inventory_position(market) == -4
    @test InventoryModels.demand!(market) == 14
    push!(market, 14,[])
    @test state(market) == [0, 10, 0.0, 10, 0.0, 10, 0.0, 10, 0.0]
    reset!(market)
    @test state(market) == [0, 10, 0.0, 10, 0.0, 10, 0.0, 10, 0.0]

    market = Market(5, Normal, 4, Normal(10,0), [20,40,60,40], 0.0)
    @test state_size(market) == 9
    @test state(market) == [10, 20, 0.0, 40, 0.0, 60, 0.0, 40, 0.0]
    @test InventoryModels.inventory_position(market) == -10
    @test InventoryModels.demand!(market) == 30
    push!(market, 6, [])
    @test InventoryModels.reward!(market) == -24*5
    @test state(market) == [24, 40, 0.0, 60, 0.0, 40, 0.0, 20, 0.0]
    @test InventoryModels.inventory_position(market) == -24
    reset!(market)
    @test state(market) == [10, 20, 0.0, 40, 0.0, 60, 0.0, 40, 0.0]

    @testset "warmup" begin
        market = Market(5, Normal, 4, 0, [20,40,60,40], 0.0, warmup = 2)
        @test state_size(market) == 9
        @test state(market) == [0, 20, 0.0, 40, 0.0, 60, 0.0, 40, 0.0]
        @test InventoryModels.inventory_position(market) == 0
        @test InventoryModels.demand!(market) == 0
        @test InventoryModels.reward!(market) == 0
        @test state(market) == [0, 20, 0.0, 40, 0.0, 60, 0.0, 40, 0.0]
        @test InventoryModels.inventory_position(market) == 0
        @test InventoryModels.demand!(market) == 0
        @test InventoryModels.reward!(market) == 0
        @test state(market) == [0, 20, 0.0, 40, 0.0, 60, 0.0, 40, 0.0]
        @test InventoryModels.inventory_position(market) == 0
        @test InventoryModels.demand!(market) == 20
        push!(market, 10, [])
        @test InventoryModels.reward!(market) == -10*5
        reset!(market)
        @test state(market) == [0, 20, 0.0, 40, 0.0, 60, 0.0, 40, 0.0]
        @test market.t == 1                      
    end
end