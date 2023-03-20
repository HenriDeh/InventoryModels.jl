"""
```
    State(init_distribution)
```
Creates a State object that contains a current value and an initial distribution.
On creation and on a `reset!` call, the value is sampled from the init_distribution with the `rand` function.
If a non random object is given as the init_distribution, the State is considered static and will always have that value.
For states with a random initial state, init_distribution can be:
- a `Distribution` object, univariate or multivariate. 
- a `Vector` of `Distribution`, in that case the state is a vector where each element is sampled from each element of `init_distribution`
- a `Vector` of functions, the function must accept an integer `idx` as an argument and return the `idx` element of the state vector. 

# Examples

```
julia> init_distribution = [(t) -> sin(π*t/5)*10 + rand(Normal()) for i in 1:6]

julia> s = State(init_distribution);

julia> state(s)
6-element Vector{Float64}:
 1.0488803860196223
 7.390000851938282
 8.143863759317055
 9.344186214885669
 6.5052926108608595
 0.889461506850406

```
"""
mutable struct State{T,D}
    val::T
    init_distribution::D
end

State(x::Union{Vector{<:Number}, Number}, T::Type = Float64) = State(T.(x), Dirac(copy(x)))
State(x::Union{Vector{<:UnivariateDistribution}, Distribution}) = State(rand.(x), x)
State(x::Vector) = State([f(t) for (t,f) in enumerate(x)], x)
RLBase.state(s::State) = s.val

RLBase.reset!(s::State{<:Any, <: Union{Vector{<:UnivariateDistribution}, Distribution}}) = s.val = rand.(s.init_distribution)
RLBase.reset!(s::State) = s.val = [f(t) for (t,f) in enumerate(s.init_distribution)]
