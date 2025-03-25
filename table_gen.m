% William Wulff
% 02.2025

% pkg load communications

fileID = fopen('stimulus.txt', 'w');

field_size = 8; #4
prim_poly = 285; #25

C = r

for i = 1:2^field_size-1
  for j = 1:2^field_size-1
    prod = gf(i,field_size,prim_poly) * gf(j,field_size,prim_poly);
    prod_int = prod.x;
    
    fprintf(fileID,'%4d %4d %4d\n', i, j, prod_int);
  end
end

fclose(fileID);
