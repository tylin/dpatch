function [INew, scale] = convertToCanonicalSize(I, dim)
% Resize the image to a manageable size and to maintain consistency of scale.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).
[rows, cols, unused_dims] = size(I);
scale = getCanonicalScale(dim, rows, cols);
INew = imresize(I, scale);
end
