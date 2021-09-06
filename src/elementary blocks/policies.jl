struct sSPolicy end 
function (::sSPolicy)(item::AbstractItem, s::T, S::T) where T<:Number 
    ip = inventory_position(item) 
<<<<<<< HEAD
    return max(zero(ip), (ip <= s)*(S - ip))
=======
    max(0,(ip <= s)*(S - ip))
>>>>>>> hooks
end
(p::sSPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::sSPolicy) = 2
print_action(::sSPolicy) = ["s", "S"]

struct RQPolicy end

function (::RQPolicy)(item::AbstractItem, R, Q)
<<<<<<< HEAD
    max(zero(Q), (inventory_position(item) <= R)*Q)
=======
    max(0,(inventory_position(item) <= R)*Q)
>>>>>>> hooks
end
(p::RQPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::RQPolicy) = 2
print_action(::RQPolicy) = ["R", "Q"]

struct QPolicy end

function (::QPolicy)(::AbstractItem, Q)
<<<<<<< HEAD
    max(zero(Q), Q)
=======
    max(0,Q)
>>>>>>> hooks
end
(p::QPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::QPolicy) = 1
print_action(::QPolicy) = ["Q"]

struct YQPolicy end

function (::YQPolicy)(::AbstractItem, Y, Q)
<<<<<<< HEAD
    max(zero(Q), (Y > 0)*Q)
=======
    max(0,(Y > 0)*Q)
>>>>>>> hooks
end
(p::YQPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)
action_size(::YQPolicy) = 2
print_action(::YQPolicy) = ["Y", "Q"]

#(R, nQ) 
#StaticStaticPolicy
#StaticDynamicPolicy
