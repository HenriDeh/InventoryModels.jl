@testset "item.jl" begin
    sup = Supplier(100, 10, leadtime = LeadTime(1, 3, 10))
    inv = Inventory(3, 50)
    item = Item(inv, sup)
    @test state(item) == [50,10,10,10]
    @test InventoryModels.inventory_position(item) == 80
    @test state_size(item) == 4
    @test action_size(item) == 2
    dest = []
    InventoryModels.pull!(item, 30, dest)
    item([30])
    InventoryModels.dispatch!(item)
    @test InventoryModels.reward!(item) == -(100 + 10*30 + 30*3 + 50)
    @test state(item) == [30,10,10,30]
    @test dest == [30, inv]
    InventoryModels.pull!(item, 40, dest)
    item([0])
    InventoryModels.dispatch!(item)
    @test InventoryModels.reward!(item) == -(40)
    @test state(item) == [0,10,30,0]
    @test dest == [30, inv, 40, inv]
    InventoryModels.pull!(item, 20, dest)
    item([0])
    InventoryModels.dispatch!(item)
    @test InventoryModels.reward!(item) == -(30)
    @test state(item) == [0,30,0,0]
    @test dest == [30, inv, 40, inv, 10, inv]
    reset!(item)
    @test state(item) == [50,10,10,10]
    @test InventoryModels.children(item) == ()

    item2 = deepcopy(item)
    inv3 = Inventory(7, 30)
    ass3 = Assembly(100, 1, item => 2, item2 => 4)
    item3 = Item(inv3, ass3)
    @test state(item3) == [30]
    @test InventoryModels.children(item3) == (item, item2)
    dest = []
    InventoryModels.pull!(item3, 20, dest)
    item3([10])
    item2([0])
    item([0])
    InventoryModels.dispatch!(item)
    InventoryModels.dispatch!(item2)
    InventoryModels.dispatch!(item3)
    InventoryModels.reward!(item)
    InventoryModels.reward!(item2)
    InventoryModels.reward!(item3)
    @test state(item) == [40,10,10,0]
    @test state(item2) == [20,10,10,0]
    @test state(item3) == [20]
    @test dest == [20, inv3]
end