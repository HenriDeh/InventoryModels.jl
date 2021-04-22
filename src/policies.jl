struct sSPolicy end 
function (::sSPolicy)(item::Item, s, S) 
    ip = inventory_position(item) 
    (ip <= s)*(S - ip)
end
(p::sSPolicy)(item::Item, v::AbstractVector) = p(item, v...)

action_size(::sSPolicy) = 2

struct RQPolicy end

function (::RQPolicy)(item::Item, R, Q)
    (ip <= R)*Q
end
(p::RQPolicy)(item::Item, v::AbstractVector) = p(item, v...)

action_size(::RQPolicy) = 2

struct QPolicy end

function (::QPolicy)(item::Item, Q)
    Q
end
(p::QPolicy)(item::Item, v::AbstractVector) = p(item, v...)

action_size(::QPolicy) = 1

struct BQPolicy end

function (::BQPolicy)(::Item, B, Q)
    (B > 0)*Q    
end
(p::BQPolicy)(item::Item, v::AbstractVector) = p(item, v...)
action_size(::BQPolicy) = 2

#(R, nQ) 
#StaticStaticPolicy
#StaticDynamicPolicy
