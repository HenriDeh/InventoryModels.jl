function plot_resource_utilization(fig, gp, ax, x, y, smoothing,ticks)
    xlow = fill(0, length(unique(x)))
    ylow = zeros(length(xlow))
    xhigh = zero(xlow)
    yhigh = zero(ylow)
    yall = zero(ylow)
    xall = zero(xlow)
    last = first(x)
    idx = 1
    for (new, ut) in zip(x, y)
        idx += new !== last
        last = new
        if ut > 1
            yhigh[idx] += ut
            xhigh[idx] += 1
        else
            ylow[idx] += ut
            xlow[idx] += 1
        end
        yall[idx] += ut
        xall[idx] += 1
    end
    ylow ./=  [n == 0 ? 1 : n for n in xlow]
    yhigh ./=  [n == 0 ? 1 : n for n in xhigh]
    yall ./= xall
    perhigh = xhigh ./(xlow .+ xhigh)
    if smoothing
        ylow = accumulate!((o,n) -> o*0.8+n*0.2, ylow,ylow)
        yhigh = accumulate!((o,n) -> o*0.8+n*0.2, yhigh,yhigh)
        yall = accumulate!((o,n) -> o*0.8+n*0.2, yall,yall)
    end
    b = barplot!(ax,ticks, perhigh, color = :gray80)
    l1 = lines!(ax,ticks, yhigh, color = :red)
    l2 = lines!(ax,ticks, ylow, color = :green)
    l3 = lines!(ax,ticks, yall, color = :blue)
    gp[2,1] = Legend(fig, [b,l1,l2,l3], ["% over capacity", "mean over capacity","mean under capacity", "mean utilization"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end
function plot_ressource_setups(fig,gp,ax,x,y, smoothing,ticks)
    yint = Int.(y)
    ys = sort(unique(yint)) #grps
    counts = zeros(length(ys), maximum(x))
    xcounts = fill(0, 1, maximum(x))
    last = first(x)
    idx = 1
    for (new, b) in zip(x, yint)
        idx += new !== last
        last = new
        xcounts[idx] += 1
        counts[setups, idx] += 1
    end
    xs = repeat(unique(x), inner = length(ys))
    counts ./= xcounts
    grp = repeat(ys, outer = maximum(x))
    pal = ax.attributes[:palette][:color][]
    barplot!(ax,ticks,xs, vec(counts), stack=grp, color = [pal[g] for g in grp])
    labels = string.(ys)
    gp[2,1] = Legend(fig, [PolyElement(color = i) for i in [pal[j] for j in ys]], labels, "# setups", tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end