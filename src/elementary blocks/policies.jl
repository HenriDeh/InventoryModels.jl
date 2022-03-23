export sSmsPolicy

struct sSPolicy end 
function (::sSPolicy)(item::AbstractItem, s::T, S::T) where T<:Number 
    ip = inventory_position(item) 
    max(0,(ip <= s)*(S - ip))
end
(p::sSPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::sSPolicy) = 2
print_action(::sSPolicy) = ["s", "S"]

struct RQPolicy end

function (::RQPolicy)(item::AbstractItem, R, Q)
    max(0,(inventory_position(item) <= R)*Q)
end
(p::RQPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::RQPolicy) = 2
print_action(::RQPolicy) = ["R", "Q"]

struct QPolicy end

function (::QPolicy)(::AbstractItem, Q)
    max(0,Q)
end
(p::QPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::QPolicy) = 1
print_action(::QPolicy) = ["Q"]

struct YQPolicy end

function (::YQPolicy)(::AbstractItem, Y, Q)
    max(0,(Y > 0)*Q)
end
(p::YQPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)
action_size(::YQPolicy) = 2
print_action(::YQPolicy) = ["Y", "Q"]

struct sSmsPolicy end 
function (::sSmsPolicy)(item::AbstractItem, s::T, Sms::T) where T<:Number 
    ip = inventory_position(item) 
    max(0,(ip <= s)*(Sms+s - ip))
end
(p::sSmsPolicy)(item::AbstractItem, v::AbstractVector) = p(item, v...)

action_size(::sSmsPolicy) = 2
print_action(::sSmsPolicy) = ["s", "S-s"]

#(R, nQ) 
#StaticStaticPolicy
#StaticDynamicPolicy
