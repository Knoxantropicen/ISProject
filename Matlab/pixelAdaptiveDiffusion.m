function C = pixelAdaptiveDiffusion(T,X0,r,F,SCHEME,STATE)

assert(strcmp(STATE,'EN')||strcmp(STATE,'DE'));

[M,N,CN] = size(T);
R = LSS_PRNG_sequence(X0,r,M*N*CN);
R = floor(mod(R.*2^32, F));
Q = reshape(R,[M,N,CN]);
C = zeros(M,N,CN);

if strcmp(STATE, 'EN')
    if strcmp(SCHEME, 'BX')
        C(1,1,:) = bitxor(bitxor(T(1,1,:),T(M,N,:)),Q(1,1,:));
        for j = 2:N
            C(1,j,:) = bitxor(bitxor(T(1,j,:),C(M,j-1,:)),Q(1,j,:));
        end
        for i = 2:M
            for j = 1:N
                C(i,j,:) = bitxor(bitxor(T(i,j,:),C(i-1,j,:)),Q(i,j,:));
            end
        end
    else
        C(1,1,:) = mod(T(1,1,:)+T(M,N,:)+Q(1,1,:),F);
        for j = 2:N
            C(1,j,:) = mod(T(1,j,:)+C(M,j-1,:)+Q(1,j,:),F);
        end
        for i = 2:M
            for j = 1:N
                C(i,j,:) = mod(T(i,j,:)+C(i-1,j,:)+Q(i,j,:),F);
            end
        end
    end
else
    if strcmp(SCHEME, 'BX')
        for i = M:-1:2
            for j = N:-1:1
                C(i,j,:) = bitxor(bitxor(T(i,j,:),T(i-1,j,:)),Q(i,j,:));
            end
        end
        for j = N:-1:2
            C(1,j,:) = bitxor(bitxor(T(1,j,:),T(M,j-1,:)),Q(1,j,:));
        end
        C(1,1,:) = bitxor(bitxor(T(1,1,:),C(M,N,:)),Q(1,1,:));
    else
        for i = M:-1:2
            for j = N:-1:1
                C(i,j,:) = mod(T(i,j,:)-T(i-1,j,:)-Q(i,j,:),F);
            end
        end
        for j = N:-1:2
            C(1,j,:) = mod(T(1,j,:)-T(M,j-1,:)-Q(1,j,:),F);
        end
        C(1,1,:) = mod(T(1,1,:)-C(M,N,:)-Q(1,1,:),F);
    end
end

end