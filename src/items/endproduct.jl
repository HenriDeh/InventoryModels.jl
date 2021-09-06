mutable struct EndProduct{M<:Market, I<:Inventory, S<:Tuple, P} <: AbstractItem
    market::M 
    inventory::I 
    sources::S
    policy::P
    position_log::Vector{Float64}
    name::String
end

function EndProduct(market::Market, inventory::Inventory, sources::Union{Assembly, Supplier}...; policy = sSPolicy(), name = "product")
    if inventory.onhand < 0
        market.backorder -= inventory.onhand
        inventory.onhand = 0
    end
    EndProduct(market, inventory, sources, policy, zeros(0), name)
end

state(e::EndProduct) = [state(e.market); state(e.inventory); reduce(vcat,[state(source) for source in e.sources])]
state_size(e::EndProduct) = state_size(e.market) + state_size(e.inventory) + sum(map(state_size, e.sources)) 
action_size(e::EndProduct) = action_size(e.policy)*length(e.sources)
function print_state(e::EndProduct)
    ps = [print_state(e.market); print_state(e.inventory); reduce(vcat, print_state.(e.sources))]
    return [e.name*" "*first(p) => last(p) for p in ps] 
end
function print_action(e::EndProduct) 
    reduce(vcat, [e.name .* " " .* source.name .* " " .* print_action(e.policy) for source in e.sources])
end

function pull!(e::EndProduct, quantity::Number, issuer)
    pull!(e.inventory, quantity, issuer)
end

function (e::EndProduct)(Qs)
    demand = demand!(e.market)
    pull!(e.inventory, demand, e.market)
    for (source, Q) in zip(e.sources, Qs)
        pull!(source, Q, e.inventory)
    end
end

function dispatch!(e::EndProduct)
    for source in e.sources
        dispatch!(source)
    end
    dispatch!(e.inventory)
end

function reward!(e::EndProduct)
    r = 0.
    r += reward!(e.market)
    r += reward!(e.inventory)
    for source in e.sources
        r += reward!(source)
    end
    push!(e.position_log, inventory_position(e))
    return r
end

function reset!(e::EndProduct)
    reset!(e.market)
    reset!(e.inventory)
    for source in e.sources
        reset!(source)
    end
    if e.inventory.onhand < 0
        e.market.backorder -= e.inventory.onhand
        e.inventory.onhand = 0
    end
    empty!(e.position_log)
    return nothing
end

function inventory_position(e::EndProduct)
    ip = inventory_position(e.inventory)
    ip += inventory_position(e.market)
    for source in e.sources
        ip += inventory_position(source)
    end
    return ip
end

function children(e::EndProduct)
    mapreduce(children, (x,y) -> tuple(x..., y...), e.sources)
end

function Base.show(io::IO, e::EndProduct)
    print(io, "EndProduct(", e.name,": ")
    show(io, e.market)
    print(io, ", ")
    show(io, e.inventory)
    print(io, ", ")
    for source in e.sources
        show(io, source)
        print(io, ", ")
    end
    show(io, e.policy)
    print(io, ")")
end