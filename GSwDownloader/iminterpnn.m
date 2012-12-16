function oim=iminterpnn(iim, U, V);
%% Nearest neighbour interpolation.
    U=int16(round(U)); V=int16(round(V));
    oimR=0*U;   oimG=0*U;   oimB=0*U;
    for i=1:numel(U)
        if  0<V(i) && V(i)<=size(iim,1) && 0<U(i) && U(i)<=size(iim,2)
            oimR(i)=iim(V(i),U(i),1);
            oimG(i)=iim(V(i),U(i),2);
            oimB(i)=iim(V(i),U(i),3);
        else % out of image bounds
            oimR(i)=0;
            oimG(i)=0;
            oimB(i)=0;  
        end
    end
        oim(:,:,1)=oimR;
        oim(:,:,2)=oimG;
        oim(:,:,3)=oimB;
        oim=uint8(oim);
end