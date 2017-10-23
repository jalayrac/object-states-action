function C_aft = filter_with_constraints( C, cstr )
%FILTER_WITH_CONSTRAINTS Summary of this function goes here
%   Detailed explanation goes here

% TO DO : check if the constraints respect the global ordering
% constraint... if not allow more space where there is problem !!!!


INF = 10000;

K = size(cstr,2);
T = size(cstr,1);

C_aft = C;

time_indexes = 1:T;

for e=1:K
   C_aft(e, time_indexes(~cstr(:,e))) = INF;
end


end

