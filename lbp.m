fg = imread('foreground.bmp');
bg = imread('background.bmp');
im = imread('flower.bmp');

fg_mean = [0 0 0];
bg_mean = [0 0 0];

for x=1:size(fg, 1)
   for y=1:size(fg, 2)
       if fg[x, y] > 0
           fg_mean = fg_mean + im(x, y, :)
       elseif bg[x, y] > 0
       end
   end
end
