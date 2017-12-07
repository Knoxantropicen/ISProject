function D = decryption(C,K,SCHEME,MAX_ROUND)

% Initial states generation
bi2fl = @(K) sum(K.*2.^(-(1:length(K))));
x0_init = bi2fl(K(1:52));
r_init = bi2fl(K(53:104));
d = zeros(1,MAX_ROUND);
R = d; X0 = d; r = d;
for i = 1:MAX_ROUND
    d(i) = bi2de(K(81+i*24:104+i*24));
    R(i) = bi2fl(K(53+MAX_ROUND*24+i*52:104+MAX_ROUND*24+i*52));
    X0(i) = mod(d(i)*(x0_init+R(i)),1);
    r(i) = mod(d(i)*(r_init+R(i)),4);
end

C = double(C);
F = 2^(ceil(log2(max(C(:))+1)/8)*8);

% High speed scrambling
% Pixel adaptive diffusion
for i = MAX_ROUND:-1:1
    C = pixelAdaptiveDiffusion(C,X0(i),r(i),F,SCHEME,'DE');
    C = highSpeedScrambling(C,X0(i),r(i),'DE');
end

D = C(2:end-1,2:end-1,:);

end