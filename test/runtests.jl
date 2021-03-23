using Revise, Distributions, InventoryModels, Test

@testset "InventoryModels.jl" begin
    @testset "supplier.jl" begin
        sup = Supplier(FixedLinearOrderCost(100,10))
        @test observe(sup) == []
        @test length(observe(sup)) == 0
        dest = []
        pull!(sup, 13, dest)
        activate!(sup, [])
        @test observe(sup) == []
        @test first(sup.pull_orders) == (dest => 13)
        dispatch!(sup)
        @test reward!(sup) == -13*10-100
        @test dest == [13, sup]
        sup2 = Supplier(FixedLinearOrderCost(100,10), capacity = 5)
        pull!(sup2, 13, dest)
        activate!(sup2,[])
        @test first(sup2.pull_orders) == (dest => 5)
        @test observe(sup2) == []
        dispatch!(sup2)
        @test reward!(sup2) == -5*10-100
        @test dest == [13, sup, 5, sup2]
        @test observe(sup2) == []
        reset!(sup)
    end
    @testset "leadtime.jl" begin
        sup = Supplier(FixedLinearOrderCost(100,10))
        lt = LeadTime(LinearHoldingCost(2), 1, 10, sup)
        @test observe(lt) == [10]
        dest = []
        pull!(lt, 13, dest)
        activate!(lt, [])
        activate!(sup, [])
        @test observe(sup) == []
        @test observe(lt) == [10]
        dispatch!(sup)
        @test reward!(sup) == -13*10-100
        @test observe(lt) == [10,13]
        dispatch!(lt)
        @test reward!(lt) == -2*13
        @test dest == [10, lt]
        @test observe(lt) == [13]
        lt2 = LeadTime(LinearHoldingCost(2), 2, Uniform(-10,0), sup)
        @test observe(lt2) == [0,0]
    end
    @testset "item.jl" begin
        sup = Supplier(FixedLinearOrderCost(100,10))
        item = Item(LinearHoldingCost(3), sSPolicy(), 0, sup)
        @test observe(item) == [item.onhand] == [0]
        @test length(observe(item)) == observation_size(item) == 1
        @test action_size(item) == 2
        @test observe(item) == [item.onhand] == [0]
        @test InventoryModels.inventory_position(item) == 0
        activate!(item, [5,10])
        @test first(sup.pull_orders) == (item => 10)
        dispatch!(sup)
        dispatch!(item)
        @test reward!(sup) == -(100+10*10)
        @test reward!(item) == -30
        @test observe(item) == [item.onhand] == [10]
        @test InventoryModels.inventory_position(item) == 10

        sup2 = Supplier(FixedLinearOrderCost(100,10))
        lt2 = LeadTime(1, 0, sup2)
        item2 = Item(LinearHoldingCost(3), sSPolicy(), 0, lt2, capacity = 5)
        @test observe(item2) == [item2.onhand] == [0]
        @test length(observe(item2)) == observation_size(item2) == 1
        @test action_size(item2) == 2
        @test observe(item2) == [item2.onhand] == [0]
        @test InventoryModels.inventory_position(item2) == 0
        activate!(item2, [5,10])
        @test first(lt2.pull_orders) == (item2 => 10)
        activate!(lt2,[])
        dispatch!(sup2)
        dispatch!(lt2)
        dispatch!(item2)
        @test reward!(sup2) == -(100+10*10)
        @test reward!(lt2) == 0
        @test reward!(item2) == 0
        @test observe(item2) == [item2.onhand] == [0]
        @test observe(lt2) == [10]
        @test InventoryModels.inventory_position(item2) == 10
        activate!(item2, [4,10])
        activate!(lt2,[])
        @test first(lt2.pull_orders) == (item2 => 0)
        dispatch!(sup2)
        dispatch!(lt2)
        dispatch!(item2)
        @test reward!(sup2) == 0
        @test reward!(lt2) == 0
        @test reward!(item2) == -15
        @test observe(item2) == [item2.onhand] == [5]
        @test observe(lt2) == [0]
        @test InventoryModels.inventory_position(item2) == 5

        item3 = Item(LinearHoldingCost(1), RQPolicy(), Uniform(-10,-5), sup)
        @test observe(item3) == [item3.onhand] == [0]
        reset!(item)
        reset!(item3)
        @test observe(item) == [item.onhand] == [0]
        @test observe(item3) == [item3.onhand] == [0]
        #test multiple suppliers
        #test multiple destinations
    end
    @testset "market.jl" begin
        sup = Supplier(FixedLinearOrderCost(100,10))
        item = Item(LinearHoldingCost(3), sSPolicy(), 5, sup)
        @test_throws AssertionError market = Market(LinearStockoutCost(5), Normal, 10, item, 0, Uniform(5,15))
        market = Market(LinearStockoutCost(5), Normal, 4, item, 0, 10, 0.1)
        @test observe(market) == [0, 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
        activate!(market, [])
        demand = market.backorder
        @test first(item.pull_orders) == (market => demand)
        activate!(item, [0, 0])
        activate!(sup,[])
        dispatch!(sup)
        dispatch!(item)
        dispatch!(market)
        @test reward!(sup) == 0
        @test reward!(item) == 0
        @test reward!(market) == -5*(demand-5)
        @test observe(market) == [(demand-5), 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
        @test observe(item) == [0]
        @test observe(sup) == []
        reset!(market)
        @test observe(market) == [0, 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
        market = Market(LinearStockoutCost(5), Normal, 4, item, 0, Uniform(10,20), 0.1)
        @test observe(market) != [0, 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
        @test peek.(market.forecast_reset) == (Uniform(10,20), Dirac(0.1))
        market = Market(LinearStockoutCost(5), Normal, 4, item, Uniform(-10,0), 10, 0.1)
        @test observe(market) != [0, 10, 0.1, 10, 0.1, 10, 0.1, 10, 0.1]
        reset!(sup)
        reset!(item)
        market2 = Market(LinearStockoutCost(5), CVNormal{0.4}, 2, item, Uniform(-10,0), [20,40,60,40])
        @test observe(market2)[2:end] == [20,40]
        activate!(market2, [])
        demand = market2.backorder
        @test first(item.pull_orders) == (market2 => demand)
        activate!(item, [0, 0])
        activate!(sup,[])
        dispatch!(sup)
        dispatch!(item)
        dispatch!(market2)
        @test reward!(sup) == 0
        @test reward!(item) == 0
        @test reward!(market2) == -5*(demand-5)
        @test observe(market2) == [(demand-5), 40, 60]
        reset!(market2)
        @test observe(market2)[2:end] == [20,40]
    end
    @testset "assembly.jl" begin
        source = []
        comp1 = Item(LinearHoldingCost(1), sSPolicy(), 20, source)
        comp2 = Item(LinearHoldingCost(1), sSPolicy(), 20, source)
        ass = Assembly(FixedLinearOrderCost(100,10), comp1 => 2, comp2 => 3)
        prod = Item(LinearHoldingCost(4), sSPolicy(), 0, ass)
        activate!(prod, [1, 5])
        activate!(ass, [])
        activate!(comp1, [])
        activate!(comp2, [])
        @test first(ass.pull_orders) == (prod => 5)
        @test first(comp1.pull_orders) == (ass => 10)
        @test first(comp2.pull_orders) == (ass => 15)
        dispatch!(comp2)
        dispatch!(comp1)
        @test ass.pull_orders[comp1] == 10
        @test ass.pull_orders[comp2] == 15 
        dispatch!(ass)
        @test length(ass.pull_orders) == 1
        dispatch!(prod)
        @test prod.onhand == 5
        @test reward!(prod) == -5*4
        @test reward!(ass) == -150
        @test reward!(comp1) == -10
        @test reward!(comp2) == -5
        
        activate!(prod, [6, 9])
        activate!(ass, [])
        activate!(comp1, [])
        activate!(comp2, [])
        @test first(ass.pull_orders) == (prod => 4)
        @test first(comp1.pull_orders) == (ass => 8)
        @test first(comp2.pull_orders) == (ass => 12)
        dispatch!(comp2)
        dispatch!(comp1)
        @test ass.pull_orders[comp1] == 8
        @test ass.pull_orders[comp2] == 5 
        dispatch!(ass)
        @test length(ass.pull_orders) == 1
        dispatch!(prod)
        @test prod.onhand == 5+5/3
        @test comp1.onhand == 10 - 5/3*2
        @test comp2.onhand == 0
        @test reward!(prod) == -(5+5/3)*4
        @test reward!(ass) == -100 - 5/3*10
        @test reward!(comp1) == -(10 - 5/3*2)
        @test reward!(comp2) == -0
    end
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
                @test child in @view bom_s[i:end]
            end
        end
        @test is.bom == bom_s
        @test observation_size(is) == length(observe(is)) == 0+0+0+0+1+1+1+0+2+21+1+11
        @test action_size(is) == 10

        is2 = sl_sip(1,10,100,0.,0,[20,40,60,40])
        @test observe(is2) == [0,20,40,60,40,0]
        @test is2([14,70]) == -(100 + 0 + 50*1)
        @test observe(is2) == [0,40,60,40,0,50]
        @test is2([29,141]) == -10
        @test is2([58,114]) == -(100 + 114-60)
        @test is2([28,53]) == -(114-60-40)
        @test observe(is2) == [0,0,0,0,0, 14]
        reset!(is2)
        @test observe(is2) == [0,20,40,60,40,0]
        @test test_policy(sl_sip(1,10,100,0.25,0,[20,40,60,40]), [14,70,29,141,58,114,28,53], 10000) ≈ -363 atol = 2
    end
end
