parametrify(x::Vector{<:NumDist}) = parametrify.(x)
parametrify(x::Number) = Dirac{Float64}(x)
parametrify(x::Distribution) = x
Base.Iterators.cycle(x::NumDist) = cycle([x])

function test_policy(is::InventorySystem, policy, n = 1000; logger = ISLogger(is))
    totreward = 0.
    for _ in 1:n
        reset!(is)
        for action in partition(policy, action_size(is))
            is(action)
            totreward += reward(is)
            if is_terminated(is) break end
        end
        logger(is)
    end
    totreward/=n
end