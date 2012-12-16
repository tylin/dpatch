function str=num2strdigits(num, digits)
% The function NUM2STRDIGITS converts integer NUM to the string having the
% DIGITS number of digits. I.e. num '34' is converted to string '000032'
% when DIGITS=6.
%
% By Petr Gronat @2011

str=num2str(num);
len=length(str);

if len>digits
    error('Number of digits of givn interer is greather than required number of digits.')
end

if len<digits
    for i=1:digits-len
        str=[num2str(0) str];
    end% i-loop
end

end