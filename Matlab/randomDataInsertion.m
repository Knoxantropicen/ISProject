function C = randomDataInsertion(P,F)

[M,N,CN] = size(P);
R = randi(F-1,[2,N,CN]);
O = randi(F-1,[M+2,2,CN]);
C = zeros(M+2,N+2,CN);
C(2:(M+1),2:(N+1),:) = P;
C(1,2:(N+1),:) = R(1,:,:);
C(M+2,2:(N+1),:) = R(2,:,:);
C(:,1,:) = O(:,1,:);
C(:,N+2,:) = O(:,2,:);

end
