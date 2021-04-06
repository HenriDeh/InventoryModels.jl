function Scarf.Instance(is::InventorySystem, gamma = 1.)
    @assert 3 <= length(is.bom) <= 4
    @assert is.bom[1] isa Market
    market = is.bom[1]
    @assert is.bom[2] isa Item
    item = is.bom[2]
    @assert is.bom[end] isa Supplier
    supplier = is.bom[end]
    if length(is.bom) == 4
        @assert is.bom[3] isa LeadTime
        leadtime = is.bom[3].leadtime
    else
        leadtime =0
    end
    Instance(item.holding_cost.h, market.stockout_cost.b, supplier.order_cost.K, 
        supplier.order_cost.c, cv(market.demand_dist), leadtime, state(market)[2:end],gamma, 
        backlog = !market.lostsales)
end