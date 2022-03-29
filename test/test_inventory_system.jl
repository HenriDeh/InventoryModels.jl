using Distributions, InventoryModels
@testset "inventory_system.jl" begin
    item1 = Item(Inventory(1, 11), Supplier(100,1), Supplier(10,1, leadtime = LeadTime(1, 9)), name = "item1")
    item2 = Item(Inventory(1, 12), Supplier(100,1), name = "item2")
    item3 = Item(Inventory(1, 13), Supplier(100,1), name = "item3")
    item4 = Item(Inventory(10,14), Assembly(80,8, item1 => 2, item2 => 4), name = "item4")
    item5 = Item(Inventory(10,15), Assembly(90,2, item2 => 4, item3 =>1), name = "item5")
    item6 = EndProduct(Market(5, Normal, 4, 0, 10, 0.0), Inventory(100,52), Assembly(1280, 1, item4=>1, item5=>2), name = "item6")

    bom = [item3, item2, item5, item4, item6, item1]
    bom_s = InventoryModels.topological_order(bom)
    for (i, el) in enumerate(bom_s)
        for child in InventoryModels.children(el)
            @test child in @view bom_s[i:end]
        end
    end
    is = InventorySystem(52, bom)
    for (i, el) in enumerate(is.bom)
        for child in InventoryModels.children(el)
            @test child in @view is.bom[i:end]
        end
    end
    @test state_size(is) == length(state(is)) == 2+1+1+1+1+1+1+8
    @test state(is) == [0,10,0,10,0,10,0,10,0,52,15,13,14,12,11,9]
    @test action_size(is) == 6*2 + 2
    
    is2 = sl_sip(1,10,100,0.,0,[20,40,60,40,0,0,0,0], 0.0, horizon = 4)
    @test state(is2) == [0,20,40,60,40,0]
    is2([14,70])
    @test reward(is2) == -(100 + 0 + 50*1)
    @test state(is2) == [0,40,60,40,0,50]
    is2([29,141])
    @test reward(is2) == -10
    is2([58,114])
    @test reward(is2) == -(100 + 114-60)
    is2([28,53])
    @test reward(is2) == -(114-60-40)
    @test state(is2) == [0,0,0,0,0, 14]
    reset!(is2)
    @test state(is2) == [0,20,40,60,40,0]
    @test test_policy(sl_sip(1,10,100,0.25,0,[20,40,60,40], 0.0), [14,70,29,141,58,114,28,53], 10000) ≈ -363 atol = 2
end