function C = highSpeedScrambling(P,X0,r,STATE)

assert(strcmp(STATE,'EN')||strcmp(STATE,'DE'));

M = size(P,1); N = size(P,2);
R = LSS_PRNG_sequence(X0,r,M+N);
A = R(1:M); B = R(end-M+1:end);
[~,I] = sort(A); [~,J] = sort(B);

S = zeros(M,N);

for i = 1:M
    for j = 1:N
        m = mod(j-I(i)-1,N)+1;
        S(i,m) = J(j);
    end
end

C = P;

if STATE == 'EN'
    for i = 1:M
        for j = 1:N
            r_ = i; c = S(i,j);
            m = mod((r_-S(1,j)-1),M)+1; n = S(m,j);
            C(m,n) = P(r_,c);
        end
    end
else
    for i = 1:M
        for j = 1:N
            r_ = i; c = S(i,j);
            m = mod((r_+S(1,j)-1),M)+1; n = S(m,j);
            C(m,n) = P(r_,c);
        end
    end
end

end