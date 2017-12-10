function C = pixelAdaptiveDiffusion(T,X0,r,F,SCHEME,STATE)

assert(strcmp(STATE,'EN')||strcmp(STATE,'DE'));

[M,N,CN] = size(T);
R = LSS_PRNG_sequence(X0,r,M*N*CN);
R = floor(mod(R.*2^32, F));
Q = reshape(R,[M,N,CN]);
C = zeros(M,N,CN);

if strcmp(STATE, 'EN')
    if strcmp(SCHEME, 'BX')
        for j = 1:N
            for i = 1:M
                if i == 1 && j == 1
                    C(i,j,:) = bitxor(bitxor(T(i,j,:),T(M,N,:)),Q(i,j,:));
                elseif i == 1
                    C(i,j,:) = bitxor(bitxor(T(i,j,:),C(M,j-1,:)),Q(i,j,:));
                else
                    C(i,j,:) = bitxor(bitxor(T(i,j,:),C(i-1,j,:)),Q(i,j,:));
                end
            end
        end
    else
        for j = 1:N
            for i = 1:M
                if i == 1 && j == 1
                    C(i,j,:) = mod(T(i,j,:)+T(M,N,:)+Q(i,j,:),F);
                elseif i == 1
                    C(i,j,:) = mod(T(i,j,:)+C(M,j-1,:)+Q(i,j,:),F);
                else
                    C(i,j,:) = mod(T(i,j,:)+C(i-1,j,:)+Q(i,j,:),F);
                end
            end
        end
    end
else
    if strcmp(SCHEME, 'BX')
        for j = N:-1:1
            for i = M:-1:1
                if i == 1 && j == 1
                    C(i,j,:) = bitxor(bitxor(T(i,j,:),C(M,N,:)),Q(i,j,:));
                elseif i == 1
                    C(i,j,:) = bitxor(bitxor(T(i,j,:),T(M,j-1,:)),Q(i,j,:));
                else
                    C(i,j,:) = bitxor(bitxor(T(i,j,:),T(i-1,j,:)),Q(i,j,:));
                end
            end
        end
    else
        for j = N:-1:1
            for i = M:-1:1
                if i == 1 && j == 1
                    C(i,j,:) = mod(T(i,j,:)-C(M,N,:)-Q(i,j,:),F);
                elseif i == 1
                    C(i,j,:) = mod(T(i,j,:)-T(M,j-1,:)-Q(i,j,:),F);
                else
                    C(i,j,:) = mod(T(i,j,:)-T(i-1,j,:)-Q(i,j,:),F);
                end
            end
        end
    end
end

end