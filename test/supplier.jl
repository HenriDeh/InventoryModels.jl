@testset "supplier.jl" begin
    sup = Supplier(FixedLinearOrderCost(100,10))
    @test state(sup) == []
    @test length(state(sup)) == 0
    dest = []
    InventoryModels.pull!(sup, 13, dest)
    InventoryModels.activate!(sup, [])
    @test state(sup) == []
    @test first(sup.pull_orders) == (dest => 13)
    InventoryModels.dispatch!(sup)
    @test InventoryModels.reward!(sup) == -13*10-100
    @test dest == [13, sup]
    sup2 = Supplier(FixedLinearOrderCost(100,10), capacity = 5)
    InventoryModels.pull!(sup2, 13, dest)
    InventoryModels.activate!(sup2,[])
    @test first(sup2.pull_orders) == (dest => 5)
    @test state(sup2) == []
    InventoryModels.dispatch!(sup2)
    @test InventoryModels.reward!(sup2) == -5*10-100
    @test dest == [13, sup, 5, sup2]
    @test state(sup2) == []
    reset!(sup)
end