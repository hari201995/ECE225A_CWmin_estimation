function [activeTxCandidate,leastActiveCw] = findNextTx(backoff)
% picking the next active Tx
nonActiveTx = find(backoff);
leastActiveCw = min(backoff(nonActiveTx));
activeTxCandidate = find(backoff==leastActiveCw);
end