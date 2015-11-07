require("Images")

im = Images.imread("flower.bmp")
fg = Images.imread("foreground.bmp")
bg = Images.imread("background.bmp")
im = Images.raw(im)
fg = Images.raw(fg)
bg = Images.raw(bg)

function is_fg(i, j)
    return sum(fg[:, i, j]) > 0
end

function is_bg(i, j)
    return sum(bg[:, i, j]) > 0
end

fg_px = []
bg_px = []

for x in [1:size(im)[2]]
    for y in [1:size(im)[3]]
        pixel = convert(Array{Int32}, im[:, x, y][1:3]) / 255
        if is_fg(x, y)
            push!(fg_px, pixel)
        elseif is_bg(x, y)
            push!(bg_px, pixel)
        end
    end
end

fg_mean = mean(fg_px)
bg_mean = mean(bg_px)

fg_cov = Matrix(3,3)
fill!(fg_cov, 0)
for px in fg_px
    px_cov = Matrix(3,3)
    for i in 1:3
        for j in 1:3
            px_cov[i, j] = px[i]*px[j] - fg_mean[i]*fg_mean[j]
        end
    end
    fg_cov = fg_cov + px_cov
end
fg_cov = fg_cov / length(fg_px)

bg_cov = Matrix(3,3)
fill!(bg_cov, 0)
for px in bg_px
    px_cov = Matrix(3,3)
    for i in 1:3
        for j in 1:3
            px_cov[i, j] = px[i]*px[j] - bg_mean[i]*bg_mean[j]
        end
    end
    bg_cov = bg_cov + px_cov
end
bg_cov = bg_cov / length(bg_px)

function px(i, j)

end

function Ψxy(x, y)

end
