function dssavepng(im,outpath)
  if(size(im,3)==4)
    imwrite(im(:,:,1:3),outpath,'Alpha',im(:,:,4));
  elseif(size(im,3)==2)
    imwrite(im(:,:,1),outpath,'Alpha',im(:,:,2));
  else
    imwrite(im,outpath);
  end
end
