clear; close all;
runnable = true;
% Simulation parameters
ABSList = [99 1];  % Can contain 99 (No LTE), 1, 5 or 0
NnodesList = [1 5 10 15];  % Number of nodes contending for the channel
Niter = 100;  % Number of iterations in the simulation. Recommended: above 100
% Sampling rate of Wi-Fi tx/rx
Fs = 20e6;  % Samples per second (Hz). Keep it constant if using 20MHz BW
% Wi-Fi times in samples (numbers are microseconds)
WT.SIFS     = round(16e-6 * Fs);  % SIFS parameter
WT.SLOT     = round(9e-6 * Fs);  % Time slot for 802.11
WT.DIFS     = round(WT.SIFS + 2*WT.SLOT);  % DIFS parameter
WT.TX       = round(300e-6 * Fs);  % fixed packet transmit time
WT.ACK      = round(200e-6 * Fs);  % Time to transmit an ACK packet
WT.TIMEUNIT = round(10000e-6 * Fs); % 100TU in 1 second approximately
WT.CWmin    = 15;  % Min. contention window (scalar fixed)
WT.MaxRtx   = 7;   % Max. number of retransmissions before packet drop
WT.Fs       = Fs;  % To ease the report
% Output Parameters - performance evaluation
totTtxOK_mean_final = zeros(length(NnodesList),length(ABSList));
avTtx_mean_final = zeros(length(NnodesList),length(ABSList));
errTtx_final = zeros(length(NnodesList),length(ABSList));
avCols_mean_final = zeros(length(NnodesList),length(ABSList));
errCols_final = zeros(length(NnodesList),length(ABSList));
totCols_mean_final = zeros(length(NnodesList),length(ABSList));
tTx_final = cell(length(NnodesList),length(ABSList));
rBusy_final = cell(length(NnodesList),length(ABSList));
% Plotting parameters
LineStyleList = {'-','--',':','-.','-'};
% ColorList = {[192 192 192]./255, [144 144 144]./255,...
%              [104 104 104]./255, [48 48 48]./255};
ColorList = {[255 127 0]./255, [0 255 0]./255, [0 127 255]./255, ...
             [50 0 255]./255,  [255 0 50]./255};
% ColorList = {[192 192 192]./255, [48 48 48]./255};
% ColorList = {'k'};
% ColorList = {'r','b','g','k','m'};

for idxABS = 1:length(ABSList)
    ABSIndex = ABSList(idxABS);
    % Load LTE interference
    if     (ABSIndex==0);  load('DATA/lteInput_ABS0'); conf.lteInterf = lteInterf;
    elseif (ABSIndex==1);  load('DATA/lteInput_ABS1'); conf.lteInterf = lteInterf;
    elseif (ABSIndex==5);  load('DATA/lteInput_ABS5'); conf.lteInterf = lteInterf;
    elseif (ABSIndex==99); load('DATA/lteInput_ABS1'); conf.lteInterf = 1e-10.*lteInterf;
    else; fprintf('Wrong ABS Index\n'); return;
    end
    for idxNodes = 1:length(NnodesList)
        conf.Nnodes = NnodesList(idxNodes);
        fprintf('\tNnodes = %d\n',conf.Nnodes);
        tTxTot1 = []; colsTot1 = []; colsTot2 = []; totTxOK1 = []; busyTot1 = [];
        parfor it = 1:Niter
            % Main Function call
            [avTtx,tTxTot,avCols,colsTot,~,totTxOK,avBusy,totBusy] = ...
                fcontend_WiFiLTE(conf,WT);
            tTxTot1 = [tTxTot1 tTxTot];
            colsTot1 = [colsTot1 colsTot];
            colsTot2 = [colsTot2 sum(colsTot)];
            totTxOK1 = [totTxOK1 totTxOK]
            busyTot1 = [busyTot1 totBusy];
        end
        % Gather general results
        totTtxOK_mean_final(idxNodes,idxABS) = mean(totTxOK1);
        avTtx_mean_final(idxNodes,idxABS) = mean(tTxTot1);
        avCols_mean_final(idxNodes,idxABS) = mean(colsTot1);
        totCols_mean_final(idxNodes,idxABS) = mean(colsTot2);
        tTx_final{idxNodes,idxABS} = tTxTot1;
        rBusy_final{idxNodes,idxABS} = busyTot1;
        % Generate error statistics within a confidence interval (95%)
        ci = 0.95;  % Confidence interval for Tx  
        T_multiplier = tinv(1 - (1-ci)/2, length(tTxTot1)-1);
        ci95 = T_multiplier * std(tTxTot1) / sqrt(length(tTxTot1));
        errTtx_final(idxNodes,idxABS) = ci95;  % Error Tx Time
        ci = 0.80;  % Confidence interval for Collisions
        T_multiplier = tinv(1 - (1-ci)/2, length(colsTot1)-1);
        ci95 = T_multiplier * std(colsTot1) / sqrt(length(colsTot1));
        errCols_final(idxNodes,idxABS) = ci95;  % Error collisions
    end
end

timeStamp = regexprep(string(datetime('now')),' ','-');
save('DATA/lastResults','timeStamp','NnodesList','ABSList','tTx_final',...
     'rBusy_final','ColorList','LineStyleList','totTtxOK_mean_final',...
     'avTtx_mean_final','errTtx_final','avCols_mean_final',...
     'errCols_final','totCols_mean_final');

% Plot section
contendWiFiLTE_plot;