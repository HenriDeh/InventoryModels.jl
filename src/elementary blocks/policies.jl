struct sSPolicy end 
function (::sSPolicy)(item::AbstractItem, s, S) 
    ip = inventory_position(item) 
    (ip <= s)*(S - ip)
end
(p::sSPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::sSPolicy) = 2
print_action(::sSPolicy) = ["s", "S"]

struct RQPolicy end

function (::RQPolicy)(item::AbstractItem, R, Q)
    (inventory_position(item) <= R)*Q
end
(p::RQPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::RQPolicy) = 2
print_action(::RQPolicy) = ["R", "Q"]

struct QPolicy end

function (::QPolicy)(::AbstractItem, Q)
    Q
end
(p::QPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::QPolicy) = 1
print_action(::QPolicy) = ["Q"]

struct YQPolicy end

function (::YQPolicy)(::AbstractItem, Y, Q)
    (Y > 0)*Q    
end
(p::YQPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)
action_size(::YQPolicy) = 2
print_action(::YQPolicy) = ["Y", "Q"]

#(R, nQ) 
#StaticStaticPolicy
#StaticDynamicPolicy
