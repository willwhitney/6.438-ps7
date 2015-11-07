require("Images")
using Memoize

im = Images.imread("flower.bmp")
fg = Images.imread("foreground.bmp")
bg = Images.imread("background.bmp")
im = Images.raw(im)
fg = Images.raw(fg)
bg = Images.raw(bg)

f = open("out.txt", "w")

ϵ = 0.01

function in_bounds(location)
    if location[1] <= 0 || location[1] > 240 || location[2] <= 0 || location[2] > 160
        return false
    else
        return true
    end
end

function is_fg(i, j)
    if !in_bounds((i, j))
        error("The location ( $((i, j)) ) is out of bounds. Could not get is_fg.")
    end
    return sum(fg[:, i, j]) > 0
end

function is_bg(i, j)
    if !in_bounds((i, j))
        error("The location ( $((i, j)) ) is out of bounds. Could not get is_bg.")
    end
    return sum(bg[:, i, j]) > 0
end

function get_pixel(i, j)
    if !in_bounds((i, j))
        error("The location ( $((i, j)) ) is out of bounds. Could not get pixel.")
    end
    return convert(Array{Int32}, im[:, i, j][1:3]) / 255
end

fg_px = []
bg_px = []

for x in [1:size(im)[2]]
    for y in [1:size(im)[3]]
        pixel = get_pixel(x, y)
        if is_fg(x, y)
            push!(fg_px, pixel)
        elseif is_bg(x, y)
            push!(bg_px, pixel)
        end
    end
end

fg_mean = mean(fg_px)
bg_mean = mean(bg_px)

fg_cov = Matrix{Float64}(3,3)
fill!(fg_cov, 0)
for px in fg_px
    px_cov = Matrix{Float64}(3,3)
    for i in 1:3
        for j in 1:3
            px_cov[i, j] = px[i]*px[j] - fg_mean[i]*fg_mean[j]
        end
    end
    fg_cov = fg_cov + px_cov
end
fg_cov = fg_cov / length(fg_px)

bg_cov = Matrix{Float64}(3,3)
fill!(bg_cov, 0)
for px in bg_px
    px_cov = Matrix{Float64}(3,3)
    for i in 1:3
        for j in 1:3
            px_cov[i, j] = px[i]*px[j] - bg_mean[i]*bg_mean[j]
        end
    end
    bg_cov = bg_cov + px_cov
end
bg_cov = bg_cov / length(bg_px)

function means(x)
    if x == 0
        return bg_mean
    elseif x == 1
        return fg_mean
    else
        error("x can't be this!", x)
    end
end

function covs(x)
    if x == 0
        return bg_cov
    elseif x == 1
        return fg_cov
    else
        error("x can't be this!", x)
    end
end

@memoize function px(x, i, j)
    if is_fg(i, j)
        if x == 1
            return 1
        else
            return 0
        end
    elseif is_bg(i, j)
        if x == 0
            return 1
        else
            return 0
        end
    else
        return 0.5
    end
end

@memoize function Ψxy(x, y, i, j)
    y_mean = means(x)
    y_cov = covs(x)
    return px(x, i, j) / ( (2 * π)^(3/2) * (det(y_cov))^(1/2)) *
            exp(-1/2 * transpose(y - y_mean) * inv(y_cov) * (y - y_mean)) + ϵ
end

@memoize function Ψxx(x1, x2)
    if x1 == x2
        return 0.9
    else
        return 0.1
    end
end

function get_value(message, x)
    return message[x+1][1]
end

@memoize function m(t, i1, j1, i2, j2)
    # println(f, (t, (i1, j1), (i2, j2)))
    # flush(f)
    if t == 0
        return [1, 1]
    else
        y1 = get_pixel(i1, j1)
        y2 = get_pixel(i2, j2)
        msg = []
        for x2 in [0, 1]
            partial_msg = []
            for x1 in [0, 1]
                product = Ψxy(x1, y1, i1, j1) * Ψxx(x1, x2)

                for location in [(i1-1, j1-1), (i1-1, j1+1), (i1+1, j1-1), (i1+1, j1+1)]
                    if location[1] == i2 && location[2] == j2
                        continue
                    end
                    if !in_bounds(location)
                        continue
                    end
                    product = product * get_value(m(t-1, location[1], location[2], i1, j1), x1)
                end

                push!(partial_msg, product)
            end
            push!(msg, sum(partial_msg))
        end
        msg = msg / sum(msg)
        return msg
    end
end

function posterior(x, t, i, j)
    y = get_pixel(i, j)
    unscaled = []
    for x_poss in [0, 1]
        product = Ψxy(x_poss, y, i, j)
        for location in [(i-1, j-1), (i-1, j+1), (i+1, j-1), (i+1, j+1)]
            if !in_bounds(location)
                continue
            end
            # print(location)
            product = product * get_value(m(t, location[1], location[2], i, j), x_poss)
        end
        push!(unscaled, product)
    end
    posteriors = unscaled / sum(unscaled)
    return get_value(posteriors, x)
end

images = []
for t in 1:30
    push!(images, Matrix{Float64}(240, 160))
    for i in 1:240
        for j in 1:160
            println(f, (i, j))
            # print(i, ' ', j)
            # print(images[t])
            flush(f)
            images[t][i, j] = posterior(1, t, i, j)
        end
    end
end

Images.grayim(images[30])
for t in 1:30
    Images.imwrite(transpose(images[t]), "estimate_$(t).png")
end

zero_img = Matrix{Float64}(240, 160)
for i in 1:240
    for j in 1:160
        zero_img[i, j] = posterior(1, 0, i, j)
    end
end
Images.imwrite(transpose(zero_img), "estimate_0.png")
