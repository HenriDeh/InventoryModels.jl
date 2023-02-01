mutable struct Depot{I<:Inventory} <: AbstractItem
    inventory::I 
    position_log::Vector{Float64}
    name::String
end

function Depot(inventory::Inventory; name = "depot")
    Depot(inventory, zeros(0), name)
end

ReinforcementLearningBase.state(e::Depot) = state(e.inventory)

state_size(e::Depot) = state_size(e.inventory)
action_size(e::Depot) = 0
function print_state(e::Depot)
    ps = print_state(e.inventory)
    return [e.name*" "*first(p) => last(p) for p in ps]    
end
print_action(::Depot) = []

function pull!(e::Depot, quantity::Number, issuer)
    pull!(e.inventory, quantity, issuer)
end

function dispatch!(e::Depot)
    dispatch!(e.inventory)
end

function reward!(e::Depot)
    r = 0.
    r += reward!(e.inventory)
    push!(e.position_log, inventory_position(e))
    return r
end

function ReinforcementLearningBase.reset!(e::Depot)
    empty!(e.position_log)
    reset!(e.inventory)
    return nothing
end

function inventory_position(e::Depot)
    ip = inventory_position(e.inventory)
    return ip
end

function children(::Depot)
    ()
end

function Base.show(io::IO, e::Depot)
    print(io, "Depot(", e.name,": ")
    show(io, e.inventory)
    print(io, ")")
end