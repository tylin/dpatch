function tmpfn()
  disp('tmpfn')
  disp(feature('getpid'))
  try
    i=1;
    while(1)
      i=i+1;
    end
  catch
    disp('success')
  end
end
