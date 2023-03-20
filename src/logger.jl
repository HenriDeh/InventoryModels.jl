using DataFrames

mutable struct ISLogger
    logs::Dict{Any, DataFrame}
    nlogs::Int
end

function ISLogger(is::InventorySystem) 
    logs = Dict{String, DataFrame}()
    for item in is.bom
        logs[item.name] = DataFrame()
    end
    for cons in is.constraints
        logs[cons.name] = DataFrame()
    end
    ISLogger(logs, 0)
end

ISLogger(is::SingleItemMMFE) = ISLogger(is.env) 


function (logger::ISLogger)(is::InventorySystem; log_id = 0)
    logger.nlogs +=1
    for item in is.bom
        df = get_logs(item)
        df.simulation_id = fill(logger.nlogs,nrow(df))
        df.log_id = fill(log_id, nrow(df))
        append!(logger.logs[item.name], df)
    end
    for cons in is.constraints
        df = get_logs(cons)
        df.simulation_id = fill(logger.nlogs, nrow(df))
        df.log_id = fill(log_id, nrow(df))
        append!(logger.logs[cons.name], df)
    end
end

(logger::ISLogger)(is::SingleItemMMFE; log_id = 0) = logger(is.env; log_id = log_id)

Base.getindex(logger::ISLogger, key) = logger.logs[key]

function reset!(logger::ISLogger)
    logger.nlogs = 0
    for k in keys(logger.logs)
        logger.logs[k] = DataFrame()
    end
end

function get_logs(item::Item) 
    df = hcat(get_logs(item.inventory), map(get_logs, item.sources)...)
    df.iteration = 1:nrow(df)
    return df
end

function get_logs(ep::EndProduct)
    df = hcat(get_logs(ep.market), get_logs(ep.inventory), map(get_logs, ep.sources)...)
    df.iteration = 1:nrow(df)
    return df
end

function get_logs(ass::Assembly)
    hcat(DataFrame(assembly_batchsize = ass.batchsize_log, assembly_cost = ass.cost_log), get_logs(ass.leadtime))
end

function get_logs(inv::Inventory)
    DataFrame(inventory_onhand = inv.on_hand_log, inventory_stockout = inv.stockout_log, inventory_fillrate = inv.fillrate_log, inventory_cost = inv.cost_log)
end

function get_logs(lt::LeadTime)
    DataFrame(leadtime_cost = lt.cost_log)
end

function get_logs(ma::Market)
    DataFrame(market_demand = ma.demand_log, market_backorder = ma.backorder_log, market_fillrate = ma.fillrate_log, market_cost = ma.cost_log)
end

function get_logs(sup::Supplier)
    hcat(DataFrame(supplier_batchsize = sup.batchsize_log, supplier_cost = sup.cost_log), get_logs(sup.leadtime))
end

function get_logs(c::RessourceConstraint)
    df = DataFrame("utilization" => c.utilization_log, "setups" => c.setup_log)
    df.iteration = 1:nrow(df)
    return df
end