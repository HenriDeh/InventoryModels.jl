
abstract type AbstractConstraint end

mutable struct RessourceConstraint <: AbstractConstraint
    capacity::Float64
    variablecosts::IdDict{Any,Float64}
    utilization_log::Vector{Float64}
    setup_log::Vector{Int}
    name::String
end
RessourceConstraint(capacity, pairs; name = "") = RessourceConstraint(capacity, IdDict{Any,Float64}(pairs), zeros(0), zeros(0), name)
RessourceConstraint(capacity, pairs...; name = "") = RessourceConstraint(capacity, pairs, name = name)

function (rc::RessourceConstraint)()
    consumption = 0.0
    setups = 0
    for (element, cost) in rc.variablecosts
        q = sum(values(element.pull_orders))
        consumption += q*cost
        setups += q > 0
    end
    push!(rc.utilization_log, consumption/rc.capacity)
    push!(rc.setup_log, setups)
    if consumption > rc.capacity
        ratio = rc.capacity/consumption
        for (element, cost) in rc.variablecosts
            for destination in keys(element.pull_orders)
                element.pull_orders[destination] *= ratio
            end
        end
    end
end

function ReinforcementLearningBase.reset!(rc::RessourceConstraint)
    empty!(rc.setup_log)
    empty!(rc.utilization_log)
end 

function Base.show(io::IO, rc::RessourceConstraint)
    print(io, "Ressource $(rc.name): ")
    for (el, cost) in rc.variablecosts
        print(io, cost,"*",el.name,"+")
    end
    println(io, "\b≤",rc.capacity)
end
#=
struct RessourceConstraintSetup <: AbstractConstraint
    capacity::Float64
    variablecosts::Dict{Any,Float64}
    setupcosts::Dict{Any,Float64}
end

capacity constraint (inventories)
=#