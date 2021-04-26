@testset "inventory_system.jl" begin
    LOC = FixedLinearOrderCost
    LHC = LinearHoldingCost
    LSC = LinearStockoutCost
    sup1 = Supplier(LOC(100,1))
    sup2 = deepcopy(sup1)
    sup3 = deepcopy(sup1)
    sup4 = deepcopy(sup1)
    lt2 = LeadTime(1, 0, sup2)
    item2 = Item(LHC(1), sSPolicy(), 0, lt2, sup3)
    item3 = Item(LHC(1), sSPolicy(), 0, sup1)
    ass1 = Assembly(LOC(100,1), item3 => 2, item2 => 4)
    lt1 = LeadTime(2, 0, ass1)
    ma2 = Market(LSC(5), Normal, 10, item3, 0, 0, 1)
    item1 = Item(LHC(5), sSPolicy(), 0, lt1, sup4)
    ma1 = Market(LSC(5), CVNormal{0.4}, 10, item1, 0, 0)
    bom = [sup1, sup2, sup3, sup4, lt2, item2, item3, ass1, lt1, ma2, item1, ma1]
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
    @test state_size(is) == length(state(is)) == 0+0+0+0+1+1+1+0+2+21+1+11
    @test action_size(is) == 10

    is2 = sl_sip(1,10,100,0.,0,[20,40,60,40], 0.0)
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