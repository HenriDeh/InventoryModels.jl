@testset "leadtime.jl" begin
    lt = LeadTime(2, 3, 10)
    @test state(lt) == [10,10,10]
    @test state_size(lt) == 3
    dest = []
    InventoryModels.push!(lt, 5, dest)
    @test state(lt) == [10,10,10,5]
    @test only(lt.pull_orders) == (dest => 5)
    InventoryModels.dispatch!(lt)
    @test dest == [10, lt]
    @test state(lt) == [10,10,5]
    @test InventoryModels.reward!(lt) == -25*2
    @test isempty(lt.pull_orders)
    @test InventoryModels.inventory_position(lt) == 25
    reset!(lt)
    @test state(lt) == [10,10,10]
    @test isempty(lt.pull_orders)

    lt = LeadTime(3, Uniform(5,15))
    @test all(5 .< state(lt) .< 15)
    @test state_size(lt) == 3
    next = first(state(lt))
    dest = []
    InventoryModels.push!(lt, 5, dest)
    @test state(lt)[4] == 5
    @test only(lt.pull_orders) == (dest => 5)
    InventoryModels.dispatch!(lt)
    @test dest == [next, lt]
    @test state(lt)[3] == 5
    InventoryModels.reward!(lt) == 0
    @test isempty(lt.pull_orders)
    reset!(lt)
    @test all(5 .< state(lt) .< 15)
    @test isempty(lt.pull_orders)
end