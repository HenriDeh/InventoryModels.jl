@testset begin
    item1 = Item(Inventory(1, 1000), Supplier(100,1), name = "item1", policy = QPolicy())
    item2 = Item(Inventory(1, 1000), Supplier(100,1), name = "item2", policy = QPolicy())
    item3 = Item(Inventory(1, 1000), Supplier(100,1), name = "item3", policy = QPolicy())
    item4 = Item(Inventory(1, 1000), Supplier(100,1), name = "item4", policy = QPolicy())
    item5 = Item(Inventory(1, 1000), Assembly(100,1, item1 => 2, item2 => 4), name = "item5", policy = QPolicy())
    item6 = Item(Inventory(1, 1000), Assembly(100,1, item3 => 10, item4 => 1), name = "item6", policy = QPolicy())
    item7 = EndProduct(
        Market(5, CVNormal{0.0}, 5, 0, 10), 
        Inventory(50, 1000), 
        Assembly(100,1, item5 => 1, item6 => 2),
        policy = QPolicy(),
        name = "item7"
        )
    
    bom = [item1,item2,item3,item4,item5,item6,item7]
    hours_cons = RessourceConstraint(1680, item5.sources[1] => 5, item6.sources[1] => 1, item7.sources[1] => 15)
    is = InventorySystem(6, bom, [hours_cons])
    is([10,10,0,0,20,0,0]) 
    @test state(item1) == [1000-40] 
    @test state(item2) == [1000-80] 
    @test state(item3) == [1000-100] 
    @test state(item4) == [1000-10]
    @test state(item5) == [1000-10+20] 
    @test state(item6) == [1000-20+10] 
    @test state(item7.inventory) == [1000-10+10]
    hours_cons = hours_cons = RessourceConstraint(168, item5.sources[1] => 5, item6.sources[1] => 1, item7.sources[1] => 15)
    is = InventorySystem(6, bom, [hours_cons])
    reset!(is)
    is([10,10,0,0,20,0,0]) 
    @test state(item1) != [1000-40] 
    @test state(item2) != [1000-80] 
    @test state(item3) != [1000-100] 
    @test state(item4) != [1000-10]
    @test state(item5) != [1000-10+20] 
    @test state(item6) != [1000-20+10] 
    @test state(item7.inventory) != [1000-10+10]
    r = 168/(15*10+10+5*20)
    @test state(item5) == [1000-10r+20r] 
    @test state(item6) == [1000-20r+10r] 
    @test state(item7.inventory) == [1000-10+10r]
end