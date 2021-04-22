
abstract type AbstractConstraint end

struct RessourceConstraint <: AbstractConstraint
    capacity::Float64
    variablecosts::Dict{Any,Float64}
end

struct RessourceConstraintSetup <: AbstractConstraint
    capacity::Float64
    variablecosts::Dict{Any,Float64}
    setupcosts::Dict{Any,Float64}
end

function (rc::RessourceConstraint)()
    consumption = 0.0
    for (element, cost) in rc.variablecosts
        consumption += sum(values(element.pull_orders))*cost
    end
    if consumption > rc.capacity
        ratio = rc.capacity//consumption
        for (element, cost) in rc.variablecosts
            for destination in keys(element.pull_orders)
                element.pull_orders[destination] *= ratio
            end
        end
    end
end