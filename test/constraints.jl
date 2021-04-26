@testset begin
    LOC = FixedLinearOrderCost
    LHC = LinearHoldingCost
    LSC = LinearStockoutCost
    sup1 = Supplier(LOC(100,1))
    sup2 = deepcopy(sup1)
    sup3 = deepcopy(sup1)
    sup4 = deepcopy(sup1)
    item1 = Item(LHC(1), QPolicy(), 1000, sup1, name = "item 1")
    item2 = Item(LHC(1), QPolicy(), 1000, sup2, name = "item 2")
    item3 = Item(LHC(1), QPolicy(), 1000, sup3, name = "item 3")
    item4 = Item(LHC(1), QPolicy(), 1000, sup4, name = "item 4")
    ass1 = Assembly(LOC(100,1), item1 => 2, item2 => 4)
    ass2 = Assembly(LOC(100,1), item3 => 10, item4 => 1)
    item5 = Item(LHC(5), QPolicy(), 1000, ass1, name = "item 5")
    item6 = Item(LHC(5), QPolicy(), 1000, ass2, name = "item 6")
    ass3 = Assembly(LOC(100,1), item5 => 1, item6 => 2)
    item7 = Item(LHC(50), QPolicy(), 1000, ass3, name = "item 7")
    ma1 = Market(LSC(5), CVNormal{0.0}, 5, item7, 0, 10, name = "item 7")
    bom = [sup1, sup2, sup3, sup4, item1, item2, item3, item4, item5, item6, item7, ass1, ass2, ass3, ma1]
    hours_cons = RessourceConstraint(1680, ass1 => 5, ass2 => 1, ass3 => 15)
    is = InventorySystem(6, bom, [hours_cons])
    is([10,10,0,0,20,0,0]) 
    @test state(item1) == [1000-40] 
    @test state(item2) == [1000-80] 
    @test state(item3) == [1000-100] 
    @test state(item4) == [1000-10]
    @test state(item5) == [1000-10+20] 
    @test state(item6) == [1000-20+10] 
    @test state(item7) == [1000-10+10]
    hours_cons = RessourceConstraint(168, ass1 => 5, ass2 => 1, ass3 => 15)
    is = InventorySystem(6, bom, [hours_cons])
    reset!(is)
    is([10,10,0,0,20,0,0]) 
    @test state(item1) != [1000-40] 
    @test state(item2) != [1000-80] 
    @test state(item3) != [1000-100] 
    @test state(item4) != [1000-10]
    @test state(item5) != [1000-10+20] 
    @test state(item6) != [1000-20+10] 
    @test state(item7) != [1000-10+10]
    r = 168/(15*10+10+5*20)
    @test state(item5) == [1000-10r+20r] 
    @test state(item6) == [1000-20r+10r] 
    @test state(item7) == [1000-10+10r]
end