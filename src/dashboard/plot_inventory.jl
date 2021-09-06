function plot_mean(fig, gp, ax, x, y, smoothing,ticks)
    xall = fill(0, length(unique(x)))
    yall = zeros(size(xall))
    xpos = fill(0, length(unique(x)))
    ypos = zeros(length(xpos))
    last = first(x)
    idx = 1
    for (new, b) in zip(x, y)
        idx += new !== last
        last = new
        if  b > 0
            ypos[idx] += b
            xpos[idx] += 1
        end
        yall[idx] += b
        xall[idx] += 1
    end
    yall ./= xall
    ypos ./= [n == 0 ? one(n) : n for n in xpos]
    if smoothing
        yall = accumulate!((o,n) -> o*0.8+n*0.2, yall,yall)
        ypos = accumulate!((o,n) -> o*0.8+n*0.2, ypos,ypos)
    end
    l = lines!(ax,ticks, yall, color = :red)
    l2 = lines!(ax,ticks, ypos, color = :green)
    gp[2,1] = Legend(fig, [l,l2], ["mean", "⊕ mean"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end



