using GLMakie
using GLMakie.Makie.MakieCore: Automatic

include("plot_inventory.jl")
include("plot_market.jl")
include("plot_ressourcecons.jl")
#include("test/test_logger.jl")
#lg = logger

function make_pane!(fig, gl, lg)
    item_menu = gl[1,1] = Menu(fig, options = keys(lg.logs))
    item_menu.i_selected = 1
    df = @lift $lg[$(item_menu.selection)]
    x1label = maximum(df[].log_id) == 0 ? "simulation_id" : "log_id"
    ticks = @lift begin
        n_logs = length(unique($df[:,x1label])) 
        maxt = maximum($df[:,x1label])
        0:((n_logs>=10) ? maxt÷10 : maxt÷n_logs):maxt
    end
    ax = gl[2,1] = Axis(fig, xticks = ticks, xzoomlock = true, xpanlock = true, xlabel = "iteration")
    options = @lift names($df)[1:end-3]
    ax_menu = gl[2,1,Top()] = Menu(fig, options = options)
    exp_tog = Toggle(fig)
    gl[3,1] = grid!([exp_tog Label(fig, "Exponential smoothing")], tellwidth = false)

    x1 = @lift $df[:, x1label]
    y1 = @lift begin
        if $(ax_menu.selection) !== nothing
            $df[:, $(ax_menu.selection)]
        else
            fill(Inf, length($x1))
        end
    end
    @lift make_plot!(fig, gl, ax, $(ax_menu.selection), $x1, $y1, $(exp_tog.active))
    return nothing
end

function make_plot!(fig, gp, ax, selection, x, y, smoothing)
    empty!(ax)
    for c in contents(gp)
        if c isa Legend
            delete!(c)
        end
    end
    reset_limits!(ax)
    ax.yticks = Automatic()
    if selection === nothing
        nothing
    elseif selection == "utilization"
        plot_resource_utilization(fig, gp,ax,x,y, smoothing)
    elseif selection == "setups"
        plot_ressource_setups(fig, gp,ax,x,y, smoothing)
    elseif selection == "market_backorder"
        plot_stockout(fig, gp,ax,x,y, smoothing)
    elseif selection == "market_fillrate"
        plot_fillrate(fig, gp,ax,x,y, smoothing)
    elseif endswith(selection, "_cost") || endswith(selection, "_batchsize")
        plot_mean(fig, gp,ax,x,y, smoothing)
    elseif selection == "inventory_onhand"
        plot_mean(fig, gp,ax,x,y, smoothing)
    elseif selection == "inventory_stockout"
        plot_stockout(fig, gp,ax,x,y, smoothing)
    elseif selection == "inventory_fillrate"
        plot_fillrate(fig, gp,ax,x,y, smoothing)
    else
        text!(ax, "Plotting of this KPI\n is not implemented", align = (:center, :center), textsize = 25)
        nothing
    end
end

function dashboard(logger)
    f = Figure(resolution = (1600,900))
    for j in 1:2
        gl = f[1,j] = GridLayout()
        make_pane!(f, gl, logger)
    end
    display(f)
end