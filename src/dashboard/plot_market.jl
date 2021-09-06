function plot_stockout(fig, gp,ax,x,y,smoothing,ticks)
    xpos = fill(0, length(unique(x)))
    ypos = zeros(length(xpos))
    yall = zero(ypos)
    xall = zero(xpos)
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
    ypos ./= [n == 0 ? one(n) : n for n in xpos]
    yall ./= xall    
    if smoothing
        ypos = accumulate!((o,n) -> o*0.8+n*0.2, ypos,ypos)
        yall = accumulate!((o,n) -> o*0.8+n*0.2, yall,ypos)
    end
    l1 = lines!(ax,ticks, ypos, color = :red)
    l2 = lines!(ax,ticks, yall, color = :green)
    gp[2,1] = Legend(fig, [l2,l1], ["mean stockout", "mean ⊕ stockout"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end

function plot_fillrate(fig, gp,ax,x,y,smoothing,ticks)
    ax.yticks = 0:0.1:1
    xone = fill(0, length(unique(x)))
    yone = zeros(length(xone))
    yall = zero(yone)
    xall = zero(xone)
    last = first(x)
    idx = 1
    for (new, b) in zip(x, y)
        idx += new !== last
        last = new
        if b == 1
            yone[idx] += 1
        end
        yall[idx] += b
        xall[idx] += 1
    end
    yall ./= xall
    yone ./= xall
    if smoothing
        yall = accumulate!((o,n) -> o*0.8+n*0.2, yall,yall)
    end
    b = barplot!(ax,ticks, yone, color = :gray80)
    l = lines!(ax,ticks, yall, color = :red)
    gp[2,1] = Legend(fig, [b, l], ["α service", "β service"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end