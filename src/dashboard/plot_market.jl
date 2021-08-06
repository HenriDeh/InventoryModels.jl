function plot_stockout(gp,ax,x,y,smoothing)
    xpos = fill(0, maximum(x))
    ypos = zeros(length(xpos))
    yall = zero(ypos)
    xall = zero(xpos)
    for (idx, b) in zip(x,y)
        if  b > 0
            ypos[idx] += b
            xpos[idx] += 1
        end
        yall[idx] += b
        xall[idx] += 1
    end
    ypos ./= [n == 0 ? 1 : n for n in xpos]
    yall ./= xall    
    if smoothing
        ypos = accumulate!((o,n) -> o*0.8+n*0.2, ypos,ypos)
        yall = accumulate!((o,n) -> o*0.8+n*0.2, yall,ypos)
    end
    l1 = lines!(ax, ypos, color = :red)
    l2 = lines!(ax, yall, color = :green)
    Legend(gp, [l2,l1], ["mean stockout", "mean ⊕ stockout"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end

function plot_fillrate(gp,ax,x,y,smoothing)
    ax.yticks = 0:0.1:1
    xone = fill(0, maximum(x))
    yone = zeros(length(xone))
    yall = zero(yone)
    xall = zero(xone)
    for (idx, b) in zip(x,y)
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
    b = barplot!(ax, yone, color = :gray80)
    l = lines!(ax, yall, color = :red)
    Legend(gp, [b, l], ["α service", "β service"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end