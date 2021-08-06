function plot_mean(gp, ax, x, y, smoothing)
    xall = fill(0, maximum(x))
    yall = zeros(size(xall))
    for (idx, b) in zip(x,y)
        yall[idx] += b
        xall[idx] += 1
    end
    yall ./= xall
    if smoothing
        yall = accumulate!((o,n) -> o*0.8+n*0.2, yall,yall)
    end
    l = lines!(ax, yall, color = :red)
    Legend(gp, [l], ["mean"], tellwidth = false, tellhight = false, valign = :top , halign = :right)
    nothing
end



