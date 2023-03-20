@testset "endproduct.jl" begin
    sup = Supplier(100, 10, leadtime = LeadTime(1, 3, fill(10,3)))
    inv = Inventory(3, 50)
    market = Market(5, Normal, 4, 0, ([30,40,20,30], fill(0., 4)))
    item = EndProduct(market, inv, sup)
    @test state(item) == [0; [30,40,20,30]; fill(0., 4); [50,10,10,10]]
    @test InventoryModels.inventory_position(item) == 80
    @test state_size(item) == 4+9
    @test action_size(item) == 2
    dest = []
    item([30])
    InventoryModels.dispatch!(item)
    @test InventoryModels.reward!(item) == -(100 + 10*30 + 30*3 + 50)
    @test state(item) == [0; [40,20,30, 0.]; fill(0., 4); [30,10,10,30]]
    @test market.backorders.val == 0
    item([0])
    InventoryModels.dispatch!(item)
    @test InventoryModels.reward!(item) == -(40)
    @test state(item) ==  [0; [20,30, 0, 0]; fill(0., 4); [0,10,30,0]]
    @test market.backorders.val == 0
    item([0])
    InventoryModels.dispatch!(item)
    @test InventoryModels.reward!(item) == -(10*5 + 30)
    @test state(item) == [10; [30, 0, 0, 0]; fill(0., 4); [0,30,0,0]]
    @test market.backorders.val == 10
    reset!(item)
    @test state(item) == [0; [30,40,20,30]; fill(0., 4); [50,10,10,10]]
    @test InventoryModels.children(item) == ()
end