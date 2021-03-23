parametrify(x::Vector{<:NumDist}) = parametrify.(x)
parametrify(x::Number) = Dirac{Float64}(x)
parametrify(x::Distribution) = x
Base.Iterators.cycle(x::NumDist) = cycle([x])