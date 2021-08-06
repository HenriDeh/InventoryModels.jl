function plot_resource_utilization(gp, ax, x, y, smoothing)
    xlow = fill(0, maximum(x))
    ylow = zeros(length(xlow))
    xhigh = zero(xlow)
    yhigh = zero(ylow)
    yall = zero(ylow)
    xall = zero(xlow)
    for (idx, ut) in zip(x,y)
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
        ylow = accumulate((o,n) -> o*0.8+n*0.2, ylow)
        yhigh = accumulate((o,n) -> o*0.8+n*0.2, yhigh)
        yall = accumulate((o,n) -> o*0.8+n*0.2, yall)
    end
    b = barplot!(ax, perhigh, color = :gray80)
    l1 = lines!(ax, yhigh, color = :red)
    l2 = lines!(ax, ylow, color = :green)
    l3 = lines!(ax, yall, color = :blue)
    Legend(gp, [b,l1,l2,l3], ["% over capacity", "mean over capacity","mean under capacity", "mean utilization"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end
function plot_ressource_setups(gp,ax,x,y, smoothing)
    yint = Int.(y)
    ys = sort(unique(yint)) #grps
    counts = zeros(length(ys), maximum(x))
    xcounts = fill(0, 1, maximum(x))
    for (idx, setups) in zip(x, yint)
        xcounts[idx] += 1
        counts[setups, idx] += 1
    end
    xs = repeat(unique(x), inner = length(ys))
    counts ./= xcounts
    grp = repeat(ys, outer = maximum(x))
    pal = ax.attributes[:palette][:color][]
    barplot!(ax,xs, vec(counts), stack=grp, color = [pal[g] for g in grp])
    labels = string.(ys)
    Legend(gp, [PolyElement(color = i) for i in [pal[j] for j in ys]], labels, "# setups", tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end