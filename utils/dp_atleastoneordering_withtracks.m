function [y, pathk, patht] = dp_atleastoneordering_withtracks(C, PTRS, varargin)

% C is the cost matrix
% PTRS{i} contains the id of the tracks (-1 if it is a starting track,
% j-1 otherwise (C format)) from which i can come frome.
if nargin==3
    alpha = varargin{1};
else
    alpha = 0;
end

[K, T] = size(C);

C_z = alpha * ones(2*K + 1, T);
C_z(2:2:end, :) = C;

C_z = cat(2, C_z, zeros(2*K+1, 1));



INF = 1000;
% do the dynamic program
P   = zeros(2*K+1, T);
B   = -ones(2*K+1, T, 2); % used for the backtracking

% initialisation
P(1, 1)      = 0;        % case where we start at no label
P(2:end,1) = INF;

% check the starting tracks: the tracks are sorted by beginning time that's
% why we can break in the loop
beginTracks = [];
for t=1:T
    if PTRS{t}==-1
        P(1,    t)   = C_z(1, t); % case we directly start as state 1 from a track
        P(2,    t)   = C_z(2, t); % case we directly start as state 1 from a track
        P(3:end,t)   = INF;
        beginTracks  = [beginTracks, t];
    else
        break;
    end
end
endTracks = PTRS{end}+1;
% used for backtracking

% filling of the P matrix
for t=1:T
    if PTRS{t} == -1
        continue;
    end
    ptrTrack = PTRS{t};
    % else it means we are not at a starting track
    for k=1:2*K+1
        % distinguish between even/odd rows
        if mod(k,2)==0 % in an important row
            % distinction between first state and other state here
            if k==2 % if first state it is not possible to directly come from a previous state
                bestValue = INF;
                for s=ptrTrack
                    if P(k-1, s+1) < bestValue % do + 1 here because track are in C format
                        B(k, t, 1) = k-1;
                        B(k, t, 2) = s+1;
                        bestValue = P(k-1, s+1);
                    end
                    if P(k, s+1) < bestValue
                        B(k, t, 1) = k;
                        B(k, t, 2) = s+1;
                        bestValue = P(k, s+1);
                    end
                    P(k, t) = bestValue + C_z(k, t);

                end
            else % if in a future state one additional possible path is possible
                % we need to check if you have already been in a previous
                % state or not
                bestValue = INF;
                for s=ptrTrack
                    if P(k-1, s+1) < bestValue % do + 1 here because track are in C format
                        B(k, t, 1) = k-1;
                        B(k, t, 2) = s+1;
                        bestValue  = P(k-1, s+1);
                    end
                    if P(k, s+1) < bestValue
                        B(k, t, 1) = k;
                        B(k, t, 2) = s+1;
                        bestValue = P(k, s+1);
                    end
                    if P(k-2, s+1) < bestValue
                        B(k, t, 1) = k-2;
                        B(k, t, 2) = s+1;
                        bestValue = P(k-2, s+1);
                    end
                end
                P(k, t) = bestValue + C_z(k, t);
            end
        else
            % you can either have stayed in no state or come from the same
            % state
            if k==2*K+1 % case of the last row is a bit different
                % to be able to finish and ensure we have gone trough all states)
                bestValue = INF;
                for s=ptrTrack
                    if P(k, s+1) < bestValue
                        B(k, t, 1) = k;
                        B(k, t, 2) = s+1;
                        bestValue = P(k, s+1);
                    end
                end
                if P(k-1,t) < bestValue
                    B(k, t, 1) = k-1;
                    B(k, t, 2) = t;
                    bestValue = P(k-1, t);
                end
                P(k, t) = bestValue + C_z(k, t);
            else
                % we need to check if you have already been in a previous
                % state or not
                if k==1
                    bestValue = INF;
                    for s=ptrTrack
                        if P(k+1, s+1) < bestValue % do + 1 here because track are in C format
                            B(k, t, 1) = k+1;
                            B(k, t, 2) = s+1;
                            bestValue = P(k+1, s+1);
                        end
                        if P(k, s+1) < bestValue
                            B(k, t, 1) = k;
                            B(k, t, 2) = s+1;
                            bestValue = P(k, s+1);
                        end
                    end
                    P(k, t) = bestValue + C_z(k, t);
                else
                    bestValue = INF;
                    for s=ptrTrack
                        if P(k-1, s+1) < bestValue % do + 1 here because track are in C format
                            B(k, t, 1) = k-1;
                            B(k, t, 2) = s+1;
                            bestValue = P(k-1, s+1);
                        end
                        if P(k, s+1) < bestValue
                            B(k, t, 1) = k;
                            B(k, t, 2) = s+1;
                            bestValue = P(k, s+1);
                        end
                        if P(k+1, s+1) < bestValue
                            B(k, t, 1) = k+1;
                            B(k, t, 2) = s+1;
                            bestValue = P(k+1, s+1);
                        end
                    end
                    P(k, t) = bestValue + C_z(k, t);
                end
            end
        end
    end
end

% backtracking
y = zeros(2*K+1, T);
possibleEnds = P(2*K:2*K+1, endTracks);
[~, argmin] = min(possibleEnds(:));

[k, t] = ind2sub(size(possibleEnds), argmin);
k = 2*K-1+k;
t = endTracks(t);
y(k, t) = 1;
current_time_pointer  = B(k, t, 2);
current_state_pointer = B(k, t, 1);
while ~ismember(current_time_pointer, beginTracks)
    k = current_state_pointer;
    t = current_time_pointer;
    y(k, t) = 1;
    current_time_pointer  = B(k, t, 2);
    current_state_pointer = B(k, t, 1);
end
y(current_state_pointer,current_time_pointer) = 1;

% backtracking
y(1:2:end, :) = [];
[pathk, patht] = find(y);

end
