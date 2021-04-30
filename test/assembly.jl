@testset "assembly.jl" begin
    comp1 = Inventory(0, 50)
    comp2 = Inventory(0, 20)
    ass = Assembly(100,10, comp1 => 2, comp2 =>1)
    @test state(ass) == []
    @test state_size(ass) == 0
    dest = []
    InventoryModels.pull!(ass, 10, dest)
    InventoryModels.dispatch!(comp1)
    InventoryModels.dispatch!(comp2)
    InventoryModels.dispatch!(ass)
    InventoryModels.reward!(comp1)
    InventoryModels.reward!(comp2)
    @test InventoryModels.reward!(ass) == -100 - 100
    @test dest == [10, ass.leadtime]
    @test state(ass) == []
    @test state(comp1) == [30]
    @test state(comp2) == [10]
    InventoryModels.pull!(ass, 12, dest)
    InventoryModels.dispatch!(comp1)
    InventoryModels.dispatch!(comp2)
    InventoryModels.dispatch!(ass)
    InventoryModels.reward!(comp1)
    InventoryModels.reward!(comp2)
    @test InventoryModels.reward!(ass) == -100 - 100
    @test dest == [10, ass.leadtime, 10, ass.leadtime]
    @test state(ass) == []
    @test state(comp1) == [10]
    @test state(comp2) == [0]

    comp1 = Inventory(0, 50)
    comp2 = Inventory(0, 20)
    ass = Assembly(100,10, comp1 => 2, comp2 =>1, leadtime = LeadTime(3, 20))
    @test state(ass) == [20,20,20]
    @test state_size(ass) == 3
    dest = []
    InventoryModels.pull!(ass, 10, dest)
    InventoryModels.dispatch!(comp1)
    InventoryModels.dispatch!(comp2)
    InventoryModels.dispatch!(ass)
    InventoryModels.reward!(comp1)
    InventoryModels.reward!(comp2)
    @test InventoryModels.reward!(ass) == -100 - 100
    @test dest == [20, ass.leadtime]
    @test state(ass) == [20,20,10]
    @test state(comp1) == [30]
    @test state(comp2) == [10]
    InventoryModels.pull!(ass, 12, dest)
    InventoryModels.dispatch!(comp1)
    InventoryModels.dispatch!(comp2)
    InventoryModels.dispatch!(ass)
    InventoryModels.reward!(comp1)
    InventoryModels.reward!(comp2)
    @test InventoryModels.reward!(ass) == -100 - 100
    @test dest == [20, ass.leadtime, 20, ass.leadtime]
    @test state(ass) == [20,10,10]
    @test state(comp1) == [10]
    @test state(comp2) == [0]
end