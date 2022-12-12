function [activeTxCandidate,leastActiveCw,sta,backoff] = findNextTx(backoff,sta)
foundTx = 0;
% picking the next active Tx
while(~foundTx)
    nonActiveTx = find(backoff);
    leastActiveCw = min(backoff(nonActiveTx));
    activeTxCandidate = find(backoff==leastActiveCw);
    if length(activeTxCandidate)>1
        for k=1:length(activeTxCandidate)
            sta(activeTxCandidate(k)).collision = sta(activeTxCandidate(k)).collision +1; 
            sta(activeTxCandidate(k)).collision = sta(activeTxCandidate(k)).collision +1;
            newBackoff = 2^(sta(activeTxCandidate(k)).collision)*sta(activeTxCandidate(k)).cwMin;
            if newBackoff>cwMax
                newBackoff = cwMax;
            end
            sta(activeTxCandidate(k)).backoffValue = randi([0,newBackoff-1],1,1);
            backoff(activeTxCandidate(k)) = sta(activeTxCandidate(k)).backoffValue;
        end
    else
       foundTx =1;
    end
end