function dsmapredrun(dscmd,dsidx)
  %create an empty workspace to run the command
  global ds;
  eval(dscmd);
  dssave;
end
