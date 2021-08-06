using GLMakie
using GLMakie.Makie.MakieCore: Automatic

include("plot_inventory.jl")
include("plot_market.jl")
include("plot_ressourcecons.jl")
include("../../test/test_logger.jl")
lg = logger

function make_pane!(fig, f)
    item_menu = f[1,1] = Menu(fig, options = keys(lg.logs))
    item_menu.i_selected = 1
    df = @lift $lg[$(item_menu.selection)]
    ticks = @lift begin 
        maxt = maximum($df.simulation_id)
        0:(maxt>=10 ? maxt÷10 : 1):maxt
    end
    ax = Axis(f[2,1], xticks = ticks, xzoomlock = true, xpanlock = true, xlabel = "simulation #")
    options = @lift names($df)[1:end-2]
    ax_menu = Menu(f[2,1,Top()], options = options)
    exp_tog = Toggle(fig)
    f[3,1] = grid!([exp_tog Label(fig, "Exponential smoothing")], tellwidth = false)

    x1 = @lift $df[:, "simulation_id"]
    y1 = @lift begin
        if $(ax_menu.selection) !== nothing
            $df[:, $(ax_menu.selection)]
        else
            fill(Inf, length($x1))
        end
    end
    @lift make_plot!($f[2,1], ax, $(ax_menu.selection), $x1, $y1, $(exp_tog.active))
    #p = @lift 
    #scatter!(ax, x1, y1)
    return nothing
end

function make_plot!(gp, ax, selection, x, y, smoothing)
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
        plot_resource_utilization(gp,ax,x,y, smoothing)
    elseif selection == "setups"
        plot_ressource_setups(gp,ax,x,y, smoothing)
    elseif selection == "market_backorder"
        plot_stockout(gp,ax,x,y, smoothing)
    elseif selection == "market_fillrate"
        plot_fillrate(gp,ax,x,y, smoothing)
    elseif endswith(selection, "_cost") || endswith(selection, "_batchsize")
        plot_mean(gp,ax,x,y, smoothing)
    elseif selection == "inventory_onhand"
        plot_mean(gp,ax,x,y, smoothing)
    elseif selection == "inventory_stockout"
        plot_stockout(gp,ax,x,y, smoothing)
    elseif selection == "inventory_fillrate"
        plot_fillrate(gp,ax,x,y, smoothing)
    else
        text!(ax, "Plotting of this KPI\n is not implemented", align = (:center, :center), textsize = 25)
        nothing
    end
end

begin 
    f = Figure(resolution = (1600,900))
    for i in 1:2, j in 1:2
        gl = f[i,j] = GridLayout()
        make_pane!(f, gl)
    end
    display(f)
end