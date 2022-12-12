clearvars;
close all;
diary logs.txt
%% Simulation Parameters

% in milli seconds, AP back off number data collection 
monitorTime = 10000; 

% WLAN simulation setting
numAp      = 1;
numGoodSta = 3;
numAggSta  = 1;
numSta = numGoodSta + numAggSta;

%%Contention window estimation setting
cwMin = 31;
cwMax = 1023;

% 1ms duration slot. => cw = 5 means it will wait for 5 ms before trying to 
% transmit next time.
durationOfCW = 1; 

% Max. times a pkt can be sent 
maxRetransmission = 4; 

% Pkt transmission 
maxPacketLen  = 1000; % in Bytes
maxPacketsToTx = 10; % per Tx
txTimePerHundredbytes = 0.5;  % ms per 100 bytes
txDataPerSlot = 100;

% Assume 1 Packet is 1 frame.
maxPkttoTxPerSlot = 1; 

%struct for each AP
ap = struct;
ap.buff(1:numSta)= 0;

% buffer array
pocket = [];


sta(1:numSta) = struct('cw', [], ...
    'packet', [], ...
    'tranmissionInprog',[],...
    'transmissionsDone',[], ...
    'backoffValue',[],...
    'bytesTransmitted',[]);

%create 3 Stations with different settings
for i=1:numSta

    % Struct for each Sta
    if i==4
        sta(i).cw = 2;
    else
        sta(i).cw = cwMin;
    end
    sta(i).packet = maxPacketsToTx;
    sta(i).packetPerSlot = 0;
    sta(i).tranmissionInprog = false;
    sta(i).transmissionsDone = 0; % How many packets are transmitted
    sta(i).backoffValue = 0;    
    sta(i).bytesTransmitted = 0;  % throughput per Station
    sta(i).collision = 0;
end


%pick the first tx
firstTx = randi(numSta,1,1);

%% simulate transmission
timeLeft = monitorTime;
activeTx = firstTx;
backoff = zeros(1,numSta);
cwCheckCnt = 0;


% set back off value for other Tx.                
for j=1:numSta
    if j ~= activeTx
        sta(j).backoffValue = randi([0,sta(j).cw-1],1,1);
        backoff(j)= sta(j).backoffValue ;
        %ap.buff(j) = [ap.buff(j) sta(j).backoffValue];
    end
end
while(timeLeft>=0)
    
    cwCheckCnt = cwCheckCnt +1;     

    % Find who has the channel and give backoff for other tx
    for i=1:numSta
        if i == activeTx 
            if sta(i).tranmissionInprog == false
                % Tx parameter reset
                totalpacketLen = randi(10,1,1)*maxPacketLen*0.1;
                packetLen = totalpacketLen;
                sta(i).backoffValue =0;
                sta(i).collision =0;
%                ap.buf(i) =[ap.buf(i) 0]; 
                log = sprintf("Total Packet length for Active Tx - %d is %d",activeTx,totalpacketLen);
                disp(log)
            end
            break;
        end
    end

    % Emulate Transmission
    switch activeTx
        case 1
            sta(1).tranmissionInprog = true;
            sta(1).bytesTransmitted = sta(1).bytesTransmitted + txDataPerSlot;
        case 2
            sta(2).tranmissionInprog = true;
            sta(2).bytesTransmitted = sta(2).bytesTransmitted + txDataPerSlot;
        case 3
            sta(3).tranmissionInprog = true;
            sta(3).bytesTransmitted = sta(3).bytesTransmitted +txDataPerSlot;
        case 4
            sta(4).tranmissionInprog = true;
            sta(4).bytesTransmitted = sta(4).bytesTransmitted + txDataPerSlot;
    end
    
    % Packet size yet to be transmitted 
    packetLen = packetLen - txDataPerSlot;
    
    % Status F3
    log = sprintf("\n Active Tx - %d \t Packet Length - %d \t packetLen - %d", activeTx,totalpacketLen,packetLen);
    disp(log)

    % Transmission over for the current tx. Parameter update.
    if packetLen==0

        % Current Tx updates
        sta(activeTx).transmissionsDone = sta(activeTx).transmissionsDone +1;
        sta(activeTx).packet = sta(activeTx).packet -1;
        sta(activeTx).tranmissionInprog = false;
        
        %Changing Tx F3
        log = sprintf("\n Changing Active Tx now: Active Tx - %d \t Number of packets yet to Tx by the Tx - %d \t Transmission in Progress - %d",...
            activeTx,sta(activeTx).packet,sta(activeTx).tranmissionInprog);
        disp(log)
        
        % Check if the Tx has to be deactivated.
        if sta(activeTx).packet == 0
            log = sprintf("\n Deleting active Tx after all transmissions");
            disp(log);
            pocket = [pocket sta(activeTx)]; 
            % set a large back off value
            sta(activeTx).backoffValue = 10e6;
            backoff(activeTx)=sta(activeTx).backoffValue;

            log = sprintf("\n station structure now");
            disp(log);
            disp(sta);
        end

        % picking the next active Tx and collision resolution
        [activeTxCandidate,leastActiveCw,sta] = findNextTx(backoff,sta);
        % Exponential Back off
%        ap.buff(activeTx) = [ap.buff(activeTx) sta(activeTx).backoffValue];
        % Fast forward time for next tx to transmit
        timeLeft = timeLeft - leastActiveCw*durationOfCW;

        log = sprintf("\n channel Idle for %d msecs", (leastActiveCw*durationOfCW));
        disp(log);
        log = sprintf("\n Next Active Tx - %d", activeTx);
        disp(log)
        log = sprintf("Time left - %d", timeLeft);
        disp(log)

        % modify the contention back off value due to fast forward. 
        for l=1:numSta
            if l~=activeTx
                backoff(l) = backoff(l)- leastActiveCw;
            end
        end
        activeTx = activeTxCandidate;
        continue;
    end   

    % reducing the CW for non active transmitters after every contention
    % window slot

    if cwCheckCnt == 2        
        for j=1:numSta
            if j ~= activeTx
                backoff(j) = backoff(j) -1; 
                sta(j).backoffValue =sta(j).backoffValue-1;
            end
        end
    end
    
    if isempty(sta)
        disp('simulation complete');
        break;
    end
    % less simulation time
    timeLeft = timeLeft - txTimePerHundredbytes;
    log = sprintf("Time left - %d",timeLeft);
    disp(log)

end
diary off;
pl=[];
figure;
for p=1:numSta
    pl =[pl sta(p).bytesTransmitted];
end
title("Throughput with greedy device: Greedy device - STA 4")
plot(1:4,pl)
xlabel('STATIONS ID')
ylabel('Throughput in Bytes')


