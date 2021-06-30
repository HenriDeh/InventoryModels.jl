mutable struct Item{I<:Inventory, S<:Tuple, P} <: AbstractItem
    inventory::I 
    sources::S
    policy::P
    name::String
end

function Item(inventory::Inventory, sources::Union{Assembly, Supplier}...; policy = sSPolicy(), name = "item")
    Item(inventory, sources, policy, name)
end

state(e::Item) = [state(e.inventory); reduce(vcat, [state(source) for source in e.sources])]
state_size(e::Item) = state_size(e.inventory) + sum(state_size.(e.sources)) 
action_size(e::Item) = action_size(e.policy)*length(e.sources)
function print_state(e::Item)
    ps = [print_state(e.inventory); reduce(vcat, print_state.(e.sources))]
    return [e.name*" "*first(p) => last(p) for p in ps]    
end
print_action(e::Item) = reduce(vcat, [e.name .* " " .* print_action(e.policy) .* " " .* source.name for source in e.sources])

function pull!(e::Item, quantity::Number, issuer)
    pull!(e.inventory, quantity, issuer)
end

function (e::Item)(Qs)
    for (source, Q) in zip(e.sources, Qs)
        pull!(source, Q, e.inventory)
    end
end

function dispatch!(e::Item)
    for source in e.sources
        dispatch!(source)
    end
    dispatch!(e.inventory)
end

function reward!(e::Item)
    r = 0.
    r += reward!(e.inventory)
    for source in e.sources
        r += reward!(source)
    end
    return r
end

function reset!(e::Item)
    reset!(e.inventory)
    for source in e.sources
        reset!(source)
    end
    return nothing
end

function inventory_position(e::Item)
    ip = inventory_position(e.inventory)
    for source in e.sources
        ip += inventory_position(source)
    end
    return ip
end

function children(e::Item)
    mapreduce(children, (x,y) -> tuple(x..., y...), e.sources)
end

function Base.show(io::IO, e::Item)
    print(io, "Item(", e.name,": ")
    show(io, e.inventory)
    print(io, ", ")
    for source in e.sources
        show(io, source)
        print(io, ", ")
    end
    show(io, e.policy)
    print(io, ")")
end