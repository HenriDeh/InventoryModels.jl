@testset "item.jl" begin
    sup = Supplier(FixedLinearOrderCost(100,10))
    item = Item(LinearHoldingCost(3), sSPolicy(), 0, sup)
    @test state(item) == [item.onhand] == [0]
    @test length(state(item)) == state_size(item) == 1
    @test action_size(item) == 2
    @test state(item) == [item.onhand] == [0]
    @test InventoryModels.inventory_position(item) == 0
    InventoryModels.activate!(item, [item.policy(item,[5,10])])
    @test first(sup.pull_orders) == (item => 10)
    InventoryModels.dispatch!(sup)
    InventoryModels.dispatch!(item)
    @test InventoryModels.reward!(sup) == -(100+10*10)
    @test InventoryModels.reward!(item) == -30
    @test state(item) == [item.onhand] == [10]
    @test InventoryModels.inventory_position(item) == 10

    sup2 = Supplier(FixedLinearOrderCost(100,10))
    lt2 = LeadTime(1, 0, sup2)
    item2 = Item(LinearHoldingCost(3), sSPolicy(), 0, lt2, capacity = 5)
    @test state(item2) == [item2.onhand] == [0]
    @test length(state(item2)) == state_size(item2) == 1
    @test action_size(item2) == 2
    @test state(item2) == [item2.onhand] == [0]
    @test InventoryModels.inventory_position(item2) == 0
    InventoryModels.activate!(item2, [item2.policy(item2,[5,10])])
    @test first(lt2.pull_orders) == (item2 => 10)
    InventoryModels.activate!(lt2,[])
    InventoryModels.dispatch!(sup2)
    InventoryModels.dispatch!(lt2)
    InventoryModels.dispatch!(item2)
    @test InventoryModels.reward!(sup2) == -(100+10*10)
    @test InventoryModels.reward!(lt2) == 0
    @test InventoryModels.reward!(item2) == 0
    @test state(item2) == [item2.onhand] == [0]
    @test state(lt2) == [10]
    @test InventoryModels.inventory_position(item2) == 10
    InventoryModels.activate!(item2, [item2.policy(item2,[4,10])])
    InventoryModels.activate!(lt2,[])
    @test first(lt2.pull_orders) == (item2 => 0)
    InventoryModels.dispatch!(sup2)
    InventoryModels.dispatch!(lt2)
    InventoryModels.dispatch!(item2)
    @test InventoryModels.reward!(sup2) == 0
    @test InventoryModels.reward!(lt2) == 0
    @test InventoryModels.reward!(item2) == -15
    @test state(item2) == [item2.onhand] == [5]
    @test state(lt2) == [0]
    @test InventoryModels.inventory_position(item2) == 5

    item3 = Item(LinearHoldingCost(1), RQPolicy(), Uniform(-10,-5), sup)
    @test state(item3) == [item3.onhand] == [0]
    reset!(item)
    reset!(item3)
    @test state(item) == [item.onhand] == [0]
    @test state(item3) == [item3.onhand] == [0]
    #test multiple suppliers
    #test multiple destinations
end