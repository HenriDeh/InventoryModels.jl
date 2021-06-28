using Revise, Distributions, InventoryModels, Test

@testset "InventoryModels.jl" begin
    include("test_inventory.jl")
    include("test_leadtime.jl")
    include("test_supplier.jl")
    include("test_market.jl")
    include("test_assembly.jl")
    include("test_item.jl")
    include("test_endproduct.jl")
    include("test_inventory_system.jl")
    include("test_constraints.jl")
end
