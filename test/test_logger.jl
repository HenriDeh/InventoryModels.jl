#@testset "test_logger" 
using Distributions, InventoryModels
begin
    item1 = Item(Inventory(1, 100), Supplier(100,1), name = "item1", policy = QPolicy())
    item2 = Item(Inventory(1, 50), Supplier(100,1), name = "item2", policy = QPolicy())
    item3 = EndProduct(
        Market(5, CVNormal{0.0}, 5, 0, 10), 
        Inventory(50, 15), 
        Assembly(100,1, item1 => 1, item2 => 2),
        policy = QPolicy(),
        name = "item3"
        )
    
    bom = [item1,item2,item3]
    hours_cons = RessourceConstraint(168, item1.sources[1] => 5, item2.sources[1] => 1, item3.sources[1] => 15)
    is = InventorySystem(6, bom, [hours_cons])
    logger = ISLogger(is)
    #=
    is([0,10,0])
    is([0,0,20])
    is([30,0,0])
    is([10,0,10])
    logger(is)
    reset!(is)
    for _ in 1:100
        for it in 1:6
            is(rand(0:20,3))
        end
        logger(is)
        reset!(is)
    end=#
end