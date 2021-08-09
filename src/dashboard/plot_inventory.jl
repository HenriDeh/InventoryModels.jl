function plot_mean(fig, gp, ax, x, y, smoothing)
    xall = fill(0, length(unique(x)))
    yall = zeros(size(xall))
    last = first(x)
    idx = 1
    for (new, b) in zip(x, y)
        idx += new !== last
        last = new
        yall[idx] += b
        xall[idx] += 1
    end
    yall ./= xall
    if smoothing
        yall = accumulate!((o,n) -> o*0.8+n*0.2, yall,yall)
    end
    l = lines!(ax, yall, color = :red)
    gp[2,1] = Legend(fig, [l], ["mean"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end



