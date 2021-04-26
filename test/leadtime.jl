@testset "leadtime.jl" begin
    sup = Supplier(FixedLinearOrderCost(100,10))
    lt = LeadTime(LinearHoldingCost(2), 1, 10, sup)
    @test state(lt) == [10]
    dest = []
    InventoryModels.pull!(lt, 13, dest)
    InventoryModels.activate!(lt, [])
    InventoryModels.activate!(sup, [])
    @test state(sup) == []
    @test state(lt) == [10]
    InventoryModels.dispatch!(sup)
    @test InventoryModels.reward!(sup) == -13*10-100
    @test state(lt) == [10,13]
    InventoryModels.dispatch!(lt)
    @test InventoryModels.reward!(lt) == -2*13
    @test dest == [10, lt]
    @test state(lt) == [13]
    lt2 = LeadTime(LinearHoldingCost(2), 2, Uniform(-10,0), sup)
    @test state(lt2) == [0,0]
end