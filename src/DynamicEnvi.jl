mutable struct DynamicEnvi{E,T}
    envi::E
    t::Int
    dynamic_parameters::Dict{Symbol, Vector{T}}
end

DynamicEnvi(envi, dynamic_parameters) = DynamicEnvi(envi, 1, dynamic_parameters)

function (e::DynamicEnvi)()
    for k in keys(e.dynamic_parameters)
        if length(e.dynamic_parameters[k]) >= e.t
            setfield!(e.envi,k,e.dynamic_parameters[k][e.t])
        else
            continue
        end
    end
    e.t += 1
    return nothing
end

function reset!(e::DynamicEnvi)
    e.t = 1
    for k in keys(e.dynamic_parameters)
        if !isempty(e.dynamic_parameters[k])
            setfield!(e.envi,k,e.dynamic_parameters[k][1])
        end
    end
end