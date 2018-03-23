clear; close all; clc;

% Load results from last execution
load('lastResults');
fprintf('Plotting execution from %s\n',timeStamp);

% Intermediate Variables
ABSListComplete = [99 1 5 0];
NnodesComplete = (1:1:20);
ABSList = [99 1 5 0];

%Plot ecdf for each node configuration
lgString = cell(length(NnodesList)*length(ABSList),1);
figure(1); hold on;
for a = 1:length(ABSList)
for n = 1:length(NnodesList)
    [f,x] = ecdf(tTx_final{n,a});
    color = mod(n,length(ColorList))+1;
    line = mod(a,length(LineStyleList))+1;
    plot(x,f,'LineWidth',2,'Color',ColorList{color},'LineStyle',LineStyleList{line});
    if ABSList(a)~=99
        lgString{n + length(NnodesList)*(a-1),1} = ...
          char(strcat('  ABS',{' '},num2str(ABSList(a)),{' '},'-',{' '},'Total Wi-Fi nodes =',{' '},num2str(n)));
    else
        lgString{n + length(NnodesList)*(a-1),1} = ...
          char(strcat('No LTE - ',{' '},'Total Wi-Fi nodes =',{' '},num2str(n)));
    end
end
end
lg = legend(lgString{:,1});
set(lg,'FontSize',14,'Location','SouthEast');
title('ecdf of the average transmission time (ms)','FontSize',14);
xlabel('time in ms','FontSize',14);
ylabel('ECDF','FontSize',14);
grid minor;

% Plot ecdf for each node configuration
lgString = cell(length(NnodesList)*length(ABSList),1);
figure(2); hold on;
for a = 1:length(ABSList)
for n = 1:length(NnodesList)
    [f,x] = ecdf(rBusy_final{n,a});
    color = mod(n,length(ColorList))+1;
    line = mod(a,length(LineStyleList))+1;
    plot(x,f,'LineWidth',2,'Color',ColorList{color},'LineStyle',LineStyleList{line});
    if ABSList(a)~=99
        lgString{n + length(NnodesList)*(a-1),1} = ...
          char(strcat('  ABS',{' '},num2str(ABSList(a)),{' '},'-',{' '},'Total Wi-Fi nodes =',{' '},num2str(n)));
    else
        lgString{n + length(NnodesList)*(a-1),1} = ...
          char(strcat('No LTE - ',{' '},'Total Wi-Fi nodes =',{' '},num2str(n)));
    end
end
end
lg = legend(lgString{:,1});
set(lg,'FontSize',14,'Location','SouthEast');
title('ecdf of the busy rate (%)','FontSize',14);
xlabel('time in ms','FontSize',14);
ylabel('ECDF','FontSize',14);
grid minor;

% Plot the average transmission time
leg = cell(length(ABSList),1);
figure(3); hold on;
for a = 1:length(ABSList)
    idx = find(ABSListComplete==ABSList(a));
    plot(NnodesList,avTtx_mean_final(:,idx), ...
     'Color','k','LineWidth',2,'LineStyle',LineStyleList{idx},'Marker','s');
    if ABSList(a)~=99
        leg{a} = char(strcat('ABS',{' '},num2str(ABSList(a))));
    else
        leg{a} = 'No LTE';
    end
end
for a = 1:length(ABSList)
    % We need to separate the errorbar from the plot since the legend looks
    % very ugly with the bars in it. This is a problem in R2017b and this
    % is a workaroung
    idx = find(ABSListComplete==ABSList(a));
    errorbar(NnodesList,avTtx_mean_final(:,idx),errTtx_final(:,idx), ...
     'Color','k','LineWidth',2,'LineStyle','none','Marker','s');
end
lg= legend(leg);
set(lg,'FontSize',14,'Location','NorthWest');
xlabel('Number of Wi-Fi nodes','FontSize',14);
ylabel('Time (ms)','FontSize',14);
title('Average Transmission time in milliseconds','FontSize',14);
grid minor;

% Plot the Total Number of Packets Transmitted OK
leg = cell(length(ABSList),1);
figure(4); hold on;
for a = 1:length(ABSList)
%     line = mod(a,length(LineStyleList))+1;
    idx = find(ABSListComplete==ABSList(a));
    plot(NnodesList,totTtxOK_mean_final(:,idx), ...
     'Color','k','LineWidth',2,'LineStyle',LineStyleList{idx},'Marker','s');
    if ABSList(a)~=99
        leg{a} = char(strcat('ABS',{' '},num2str(ABSList(a))));
    else
        leg{a} = 'No LTE';
    end
end
for a = 1:length(ABSList)
    % We need to separate the errorbar from the plot since the legend looks
    % very ugly with the bars in it. This is a problem in R2017b and this
    % is a workaroung
    idx = find(ABSListComplete==ABSList(a));
    errorbar(NnodesList,totTtxOK_mean_final(:,idx),errTtx_final(:,idx), ...
     'Color','k','LineWidth',2,'LineStyle','none','Marker','s');
end
lg= legend(leg);
set(lg,'FontSize',14,'Location','NorthWest');
xlabel('Number of Wi-Fi nodes','FontSize',14);
ylabel('Time (ms)','FontSize',14);
title('Total Number of tTransmissions OK','FontSize',14);
grid minor;

% Plot the average number of collisions per user
figure(5); hold on;
for a = 1:length(ABSList)
    idx = find(ABSListComplete==ABSList(a));
    plot(NnodesList,avCols_mean_final(:,idx), ...
     'Color','k','LineWidth',2,'LineStyle',LineStyleList{idx},'Marker','s');
    if ABSList(a)~=99
        leg{a} = char(strcat('ABS',{' '},num2str(ABSList(a))));
    else
        leg{a} = 'No LTE';
    end
end
for a = 1:length(ABSList)
    % We need to separate the errorbar from the plot since the legend looks
    % very ugly with the bars in it. This is a problem in R2017b and this
    % is a workaroung
    idx = find(ABSListComplete==ABSList(a));
    errorbar(NnodesList,avCols_mean_final(:,idx),errCols_final(:,idx), ...
     'Color','k','LineWidth',2,'LineStyle','none','Marker','s');
end
lg = legend(leg);
set(lg,'FontSize',14,'Location','NorthWest');
xlabel('Number of Wi-Fi nodes','FontSize',14);
ylabel('Collisions','FontSize',14);
title('Average number of collisions','FontSize',14);
grid minor;

% Plot the total number of collisions in the network
figure(6); hold on;
for a = 1:length(ABSList)
    idx = find(ABSListComplete==ABSList(a));
    plot(NnodesList,totCols_mean_final(:,idx), ...
     'Color','k','LineWidth',2,'LineStyle',LineStyleList{idx},'Marker','s');
    if ABSList(a)~=99
        leg{a} = char(strcat('ABS',{' '},num2str(ABSList(a))));
    else
        leg{a} = 'No LTE';
    end
end
for a = 1:length(ABSList)
    % We need to separate the errorbar from the plot since the legend looks
    % very ugly with the bars in it. This is a problem in R2017b and this
    % is a workaroung
    idx = find(ABSListComplete==ABSList(a));
    errorbar(NnodesList,totCols_mean_final(:,idx),errCols_final(:,idx), ...
     'Color','k','LineWidth',2,'LineStyle','none','Marker','s');
end
lg = legend(leg);
set(lg,'FontSize',14,'Location','NorthWest');
xlabel('Number of Wi-Fi nodes','FontSize',14);
ylabel('Collisions','FontSize',14);
title('Total number of collisions','FontSize',14);
grid minor;