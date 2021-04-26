struct sSPolicy end 
function (::sSPolicy)(item::Item, s, S) 
    ip = inventory_position(item) 
    (ip <= s)*(S - ip)
end
(p::sSPolicy)(item::Item, v::AbstractVector) = p(item, v...)

action_size(::sSPolicy) = 2
print_action(::sSPolicy) = ["s", "S"]

struct RQPolicy end

function (::RQPolicy)(item::Item, R, Q)
    (ip <= R)*Q
end
(p::RQPolicy)(item::Item, v::AbstractVector) = p(item, v...)

action_size(::RQPolicy) = 2
print_action(::RQPolicy) = ["R", "Q"]

struct QPolicy end

function (::QPolicy)(item::Item, Q)
    Q
end
(p::QPolicy)(item::Item, v::AbstractVector) = p(item, v...)

action_size(::QPolicy) = 1
print_action(::QPolicy) = ["Q"]

struct YQPolicy end

function (::YQPolicy)(::Item, Y, Q)
    (Y > 0)*Q    
end
(p::YQPolicy)(item::Item, v::AbstractVector) = p(item, v...)
action_size(::YQPolicy) = 2
print_action(::YQPolicy) = ["Y", "Q"]

#(R, nQ) 
#StaticStaticPolicy
#StaticDynamicPolicy
