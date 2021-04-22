using Revise, Distributions, InventoryModels, Test

@testset "InventoryModels.jl" begin
    include("test/supplier.jl")
    include("leadtime.jl")
    include("item.jl")
    include("market.jl")
    include("assembly.jl")
    include("inventory_system.jl")
    include("constraints.jl")
end
