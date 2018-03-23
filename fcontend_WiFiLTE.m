function [avTtx,tTxTot,avCols,colsTot,totDrop,totTxOK,avBusy,totBusy] = fcontend_WiFiLTE(conf,WT)
    Nnodes    = conf.Nnodes;
    lteInterf = conf.lteInterf;

    sTot     = length(lteInterf);  % Simulation time in samples
%     sIdx     = 1;  % Variable that controls the DES in samples
    sIdx     = randi(3*WT.SLOT);  % Variable that controls the DES in samples
    % Initialize devices
    for id = (1:Nnodes)
        nodes(id).id = id;  %#ok % ID of the Wi-Fi device
        nodes(id).state = 'DIFS';  %#ok % State in the DCF. The possible values are:
                                   % 'DIFS','BO','TX','SIFS,'ACK' and 'WAIT'
        nodes(id).tleft = WT.DIFS;  %#ok % Time left for transition to new state
        nodes(id).tleftBO = 0;  %#ok % Time left from previous BO
        nodes(id).flagBO = 0;  %#ok % Flag marking transition BO->DIFS (BO->TX)
        nodes(id).flagTX = 0;  %#ok % Flag marking transition TX->DIFS (TX->SIFS)
        nodes(id).idxPkt = 1;  %#ok % Index of the packet intended to be transmitted
        nodes(id).idxRtx = 0;  %#ok % Retransmission index for the upcoming packet.
        nodes(id).Ttxini = 0;  %#ok % Initial time to transmit
        nodes(id).Ttx = [];  %#ok % Average time to transmit a packet
        nodes(id).BusyRate = 0; %#ok % Time that the channel was sensed busy 
        nodes(id).Cols = 0;  %#ok % Number of collisions
        nodes(id).Drop = 0;  %#ok % Number of packet loss
    end

    % --------------------------------------------------------------------- %
    % ------------------------- SIMULATION -------------------------------- %
    % --------------------------------------------------------------------- %
    
    while((sIdx+WT.SLOT)<sTot)
        % Detect LTE interference - energy detection
        LTEchbusy = detectLTEInterference(sIdx,lteInterf,WT);
        % Detect WiFi transmissions - mark Wi-Fi collisions
        [WiFIchbusy,nodes] = detectWiFiInterference(nodes);
        % Update channel state accordingly
        nodes = updateChState(LTEchbusy,WiFIchbusy,nodes,WT,sIdx);
        % Print Network status
    %     fprintf('| %d | %d | %5s | %6.3f | %5s | %6.3f |\n',...
    %         LTEchbusy,WiFIchbusy,nodes(1).state,nodes(1).tleft,nodes(2).state,nodes(2).tleft);
        % Update time slot
        sIdx = sIdx + WT.SLOT;
        % Pause for better visualization
    %     pause(0.03);
    end
    % Report
    [avTtx,tTxTot,avCols,colsTot,totDrop,totTxOK,avBusy,totBusy] = generateReport(nodes,Nnodes,sTot);
end



% --------------------------------------------------------------------- %
% -------------------------- FUNCTIONS -------------------------------- %
% --------------------------------------------------------------------- %

% Function detect the state of the channel
% There are 4 possibilities here:
% | LTEchbusy | WiFIchbusy |    Action
% |-----------|------------|---------------------
% |     0     |     0      |    update ALL
% |     0     |     1      |    do not update BO
% |     1     |     0      |    do not update BO
% |     1     |     1      |    do not update BO
function [nodes] = updateChState(LTEchbusy,WiFichbusy,nodes,WT,sIdx)
    for id = 1:length(nodes)
        if (~strcmp(nodes(id).state,'BO')) || (LTEchbusy==0&&WiFichbusy==0)
            % Update timeleft for (1) all the states regardless of ch.state
            %                     (2) BO when channel is iddle
            nodes(id) = updateState(nodes(id),WT,sIdx);
            % Update time left
            nodes(id).tleft = nodes(id).tleft - WT.SLOT;
        elseif strcmp(nodes(id).state,'BO') && (LTEchbusy||WiFichbusy)
            % Set a flag marking the transition BO -> DIFS
            nodes(id).flagBO = 1;
            % Update Busy Rate
            nodes(id).BusyRate = nodes(id).BusyRate + WT.SLOT;
        end
    end
end

% Function that updates WiFi states
function [node] = updateState(node,WT,sIdx)
    % Check if the time to move onto a new state is completed
    timesUp = (node.tleft - WT.SLOT <= 0);
    % Check if the BO state should go onto DIFS
    boUpdate = (strcmp(node.state,'BO') && node.flagBO==1);
    % Update time left in state
    if (timesUp || boUpdate)
        node = stateTransition(node,WT,sIdx);
    end
    % Residual BO is less than the time slot. We need to postpone the
    % carrier sensing mechanism until the beginning of the next slot
    if node.tleft < WT.SLOT
        node.tleft = WT.SLOT;
    end
end

% Function that controls the state transition for the Wi-Fi 
% nodes using the standard DCF function.
% Returns the updated values of the node. Those values are:
% - flagBO: Deactivated after BO->DIFS
% - flagTX: Deactivated after TX->DIFS
% - state: New state for the Wi-Fi node
function [node] = stateTransition(node,WT,sIdx)
    flagBO = node.flagBO;  % Flag marking the BO transition
    flagTX = node.flagTX;  % Flag marking the BO transition
    switch node.state
        case 'DIFS'
                        node.state = 'BO';
            if flagBO;  tleftnew = node.tleftBO;  % Keep the previous BO value
                        node.tleftBO = 0;  % Restore residual BO time
                        node.flagBO = 0;  % Restore flag to normal state
            else;       tleftnew = selectBackoff(node.idxRtx,WT);
            end
        case 'BO' 
            % Mark the transition. Either BO->TX (Natural behavior) or
            %                             BO->DIFS (Detection during BO)
            if flagBO; node.state = 'DIFS';
                       tleftnew = WT.DIFS;
                       node.tleftBO = node.tleft;  % Residual BO time
            else;      node.state = 'TX';
                       tleftnew = WT.TX;
            end
        case 'TX'
            % Mark the transition. Either TX->SIFS (Natural behavior) or
            %                             TX->DIFS (Collision during TX)
            if flagTX; node.state = 'DIFS'; 
                       tleftnew   = WT.DIFS;
                       node.flagTX = 0;  % Restore flag to normal state
                       node.Cols = node.Cols + 1;  % Collisions update
                       if node.idxRtx == 7
                           % Drop packet
                           node.idxPkt = node.idxPkt + 1;  % Pkt idx updtd
                           node.idxRtx = 0;  % Rtx idx restored
                           node.Drop = node.Drop + 1; % pkts dropped updtd
                       else
                           % Rtx index update
                           node.idxRtx = node.idxRtx + 1;
                       end
            else;      node.state = 'SIFS';
                       tleftnew = WT.SIFS;
                       % Update packet indexes
                       node.idxPkt = node.idxPkt + 1;  % Pkt index updated
                       node.idxRtx = 0;  % Rtx index restored
                       % Generate metrics for performance evaluation
                       tTx = 1e3.*(sIdx - node.Ttxini)./WT.Fs; % time (ms)
                       node.Ttx = [node.Ttx tTx];
            end
        case 'SIFS' 
                       node.state = 'ACK'; 
                       tleftnew = WT.ACK;
        case 'ACK'
                       node.state = 'DIFS';
                       tleftnew = WT.DIFS;
                       node.Ttxini = sIdx;  % Init tx attempt update
    end
    node.tleft = node.tleft + tleftnew;
end

% Function that returns the status of the channel due to Wi-Fi interference
% status: 0 -> no Wi-Fi node is transmitting
%         N -> Number of Wi-Fi nodes occupying the channel. If N is 1,
%              there is no collision. If N is greater than 1, collision is
%              detected and the flagTX of nodes occupying the channel is
%              activated.
function [status,nodes] = detectWiFiInterference(nodes)
    WiFinodesTx = zeros(length(nodes),1);
    % Detect WiFi devices on state TX, SIFS or ACK
    for id = 1:length(nodes)
        if (strcmp(nodes(id).state,'TX') ||...
            strcmp(nodes(id).state,'SIFS') || ...
            strcmp(nodes(id).state,'ACK'))
                WiFinodesTx(id) = 1;
        end
    end
    % The status returns the number of Wi-Fi nodes occupying the channel
    status = sum(WiFinodesTx);
    % Collision detector - More than 1 node in the TX state
    if  status>1
        idList = find(WiFinodesTx==1);
        for id = (idList.')
            % Mark the transition: TX->DIFS (Collision during TX)
            nodes(id).flagTX = 1;
        end
    end
end

% Function detect the state of the channel. Returns 1 if the LTE
% interference is detected. Otherwise return 0
function status = detectLTEInterference(sIdx,inputSamples,WT)
    sampl = inputSamples(sIdx:sIdx+WT.SLOT);
    energyThreshold = 10^((-85-30)/10);
    if ((1/WT.SLOT)*sum(abs(sampl).^2)> energyThreshold)
        status = 1;
    else
        status = 0;
    end
end

% Function that selects the initial Backoff
function [sBO] = selectBackoff(idxRtx,WT)
    factor = 2^(idxRtx);
    value = randi(WT.CWmin * factor,1,1);
    sBO = WT.SLOT * value;
end

% Function that generates the report
function [avTtx,tTxTot,avCols,colsTot,totDrop,totTxOK,avBusy,totBusy] = generateReport(nodes,Nnodes,sTot)
    tTxTot = []; colsTot = []; totDrop = 0; totTxOK = 0; totBusy = [];
    for i = 1:Nnodes
        if ~isnan(mean(nodes(i).Ttx))
            tTxTot = [tTxTot nodes(i).Ttx];  %#ok
        end
        colsTot = [colsTot nodes(i).Cols];   %#ok
        totDrop = totDrop + nodes(i).Drop;
        totTxOK = totTxOK + length(nodes(i).Ttx);
        totBusy = [totBusy 100*nodes(i).BusyRate/sTot];  %#ok
%         fprintf('-- average Tx time node %d = %.3f\n',i,1e6 * mean(nodes(i).Ttx) / Fs);
%         fprintf('-- Number of collision node %d = %d\n',i,nodes(i).Cols);
%         fprintf('-- Number of Packets dropped node %d = %d\n',i,nodes(i).Drop);
%         fprintf('-- Number of Packets Tx %d = %d\n',i,length(nodes(i).Ttx));
%         [f,x] = ecdf(nodes(i).Ttx);
%         figure(1); hold on;
%         plot(x,f);
    end
    avTtx = mean(tTxTot);
    avCols = mean(colsTot);
    avBusy = mean(totBusy);
    fprintf('- average Tx time = %.3f (ms)\n',avTtx);
    fprintf('- average Collisions = %.3f (%.3f%%)\n',avCols,100*avCols/(totDrop+totTxOK));
    fprintf('- Total Packets dropped = %.3f\n',totDrop);
    fprintf('- Total Packets Tx = %d (%d%%)\n',totTxOK,100*totTxOK/(totDrop+totTxOK));
    fprintf('- Drop Rate = %d\n',totDrop/(totDrop+totTxOK));
end