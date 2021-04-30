using Revise, Distributions, InventoryModels, Test

@testset "InventoryModels.jl" begin
    include("inventory.jl")
    include("leadtime.jl")
    include("supplier.jl")
    include("market.jl")
    include("assembly.jl")
    include("item.jl")
    include("endproduct.jl")
    include("inventory_system.jl")
    include("constraints.jl")
end
