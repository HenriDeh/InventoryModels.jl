 @testset "inventory.jl" begin
    inv = Inventory(3, 10)
    @test state(inv) == [inv.onhand] == [10]
    @test length(state(inv)) == state_size(inv) == 1
    @test InventoryModels.inventory_position(inv) == 10
    dest = []
    InventoryModels.pull!(inv, 7, dest)
    @test only(inv.pull_orders) == (dest => 7)
    InventoryModels.dispatch!(inv)
    @test InventoryModels.reward!(inv) == -3*3
    @test state(inv) == [3]
    @test dest == [7, inv]
    InventoryModels.pull!(inv, 7, dest)
    @test only(inv.pull_orders) == (dest => 7)
    InventoryModels.dispatch!(inv)
    @test InventoryModels.reward!(inv) == 0
    @test state(inv) == [0]
    @test dest == [7, inv, 3, inv]
    reset!(inv)
    @test state(inv) == [inv.onhand] == [10]
    @test InventoryModels.inventory_position(inv) == 10
    dest2 = []
    InventoryModels.pull!(inv, 10, dest)
    InventoryModels.pull!(inv, 5, dest2)
    @test length(inv.pull_orders) == 2
    InventoryModels.dispatch!(inv)
    @test InventoryModels.reward!(inv) == 0
    @test state(inv) == [0]
    @test dest == [7, inv, 3, inv, 2/3*10, inv]
    @test dest2 == [2/3*5, inv]

    inv = Inventory(3, Uniform(10,20), capacity = 10)
    @test state(inv) == [10]
    push!(inv, 10, dest)
    @test state(inv) == [10]
    inv.capacity = 20
    reset!(inv)
    @test 10 < inv.onhand < 20
    
end