@testset "supplier.jl" begin
    sup = Supplier(100, 10)
    @test state(sup) == []
    @test state_size(sup) == 0
    dest = []
    InventoryModels.pull!(sup, 13, dest)
    @test state(sup) == []
    @test only(sup.pull_orders) == (dest => 13)
    InventoryModels.dispatch!(sup)
    @test InventoryModels.reward!(sup) == -13*10-100
    @test dest == [13, sup.leadtime]

    sup2 = Supplier(FixedLinearOrderCost(100,10), capacity = 5)
    InventoryModels.pull!(sup2, 13, dest)
    @test only(sup2.pull_orders) == (dest => 5)
    @test state(sup2) == []
    InventoryModels.dispatch!(sup2)
    @test InventoryModels.reward!(sup2) == -5*10-100
    @test dest == [13, sup.leadtime, 5, sup2.leadtime]
    @test state(sup2) == []
    reset!(sup)

    sup = Supplier(100, 10, leadtime = LeadTime(1, 3, fill(10,3)))
    @test state(sup) == [10,10,10]
    @test state_size(sup) == 3
    dest = []
    InventoryModels.pull!(sup, 13, dest)
    @test only(sup.pull_orders) == (dest => 13)
    InventoryModels.dispatch!(sup)
    @test state(sup) == [10,10,13]
    @test only(sup.leadtime.pull_orders) == (dest => 13)
    @test InventoryModels.reward!(sup) == -13*10-100 - 33
    @test dest == [10, sup.leadtime]
    @test InventoryModels.inventory_position(sup) == 33
end