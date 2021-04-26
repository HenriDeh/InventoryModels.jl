@testset "assembly.jl" begin
    source = []
    comp1 = Item(LinearHoldingCost(1), sSPolicy(), 20, source)
    comp2 = Item(LinearHoldingCost(1), sSPolicy(), 20, source)
    ass = Assembly(FixedLinearOrderCost(100,10), comp1 => 2, comp2 => 3)
    prod = Item(LinearHoldingCost(4), sSPolicy(), 0, ass)
    InventoryModels.activate!(prod, [5])
    InventoryModels.activate!(ass, [])
    InventoryModels.activate!(comp1, [])
    InventoryModels.activate!(comp2, [])
    @test first(ass.pull_orders) == (prod => 5)
    @test first(comp1.pull_orders) == (ass => 10)
    @test first(comp2.pull_orders) == (ass => 15)
    InventoryModels.dispatch!(comp2)
    InventoryModels.dispatch!(comp1)
    @test ass.pull_orders[comp1] == 10
    @test ass.pull_orders[comp2] == 15 
    InventoryModels.dispatch!(ass)
    @test length(ass.pull_orders) == 1
    InventoryModels.dispatch!(prod)
    @test prod.onhand == 5
    @test InventoryModels.reward!(prod) == -5*4
    @test InventoryModels.reward!(ass) == -150
    @test InventoryModels.reward!(comp1) == -10
    @test InventoryModels.reward!(comp2) == -5
    
    InventoryModels.activate!(prod, [prod.policy(prod,[6, 9])])
    InventoryModels.activate!(ass, [])
    InventoryModels.activate!(comp1, [])
    InventoryModels.activate!(comp2, [])
    @test first(ass.pull_orders) == (prod => 4)
    @test first(comp1.pull_orders) == (ass => 8)
    @test first(comp2.pull_orders) == (ass => 12)
    InventoryModels.dispatch!(comp2)
    InventoryModels.dispatch!(comp1)
    @test ass.pull_orders[comp1] == 8
    @test ass.pull_orders[comp2] == 5 
    InventoryModels.dispatch!(ass)
    @test length(ass.pull_orders) == 1
    InventoryModels.dispatch!(prod)
    @test prod.onhand == 5+5/3
    @test comp1.onhand == 10 - 5/3*2
    @test comp2.onhand == 0
    @test InventoryModels.reward!(prod) == -(5+5/3)*4
    @test InventoryModels.reward!(ass) == -100 - 5/3*10
    @test InventoryModels.reward!(comp1) == -(10 - 5/3*2)
    @test InventoryModels.reward!(comp2) == -0
end