function R = LSS_PRNG_sequence(x,r,len)

R = zeros(1,len);
for i = 1:len
    x = LSS_PRNG(x,r);
    R(i) = x;
end

end

function x_ = LSS_PRNG(x,r)

x_ = mod(r*x*(1-x)+(4-r)*sin(pi*x)/4,1);

end