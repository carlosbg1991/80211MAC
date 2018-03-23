name1 = 'NodesPerCluster_final.fig';
name2 = 'ABStot2.fig';

h1 = openfig(name1,'reuse'); % open figure
ax1 = gca; % get handle to axes of figure
h2 = openfig(name2,'reuse');
ax2 = gca;
h3 = figure; %create new figure
s1 = subplot(1,2,1); %create and get handle to the subplot axes
s2 = subplot(1,2,2);
fig1 = get(ax1,'children'); %get handle to all the children in the figure
fig2 = get(ax2,'children');
copyobj(fig1,s1); %copy children to new parent axes i.e. the subplot axes
copyobj(fig2,s2);
subplot(1,2,1);
xlabel('Wi-Fi nodes','FontSize',14);
ylabel('Distribution (%)','FontSize',14);
title('Number of nodes per group - ABS1','FontSize',14);
grid minor
subplot(1,2,2)
title('Average transmission time','FontSize',14);
xlabel('time (ms)','FontSize',14);
ylabel('ECDF','FontSize',14);
grid minor;
subplot(1,2,1);
lg = legend('  5 nodes','{figs/fair_nodes_scheduling_matlab.eps}}10 nodes','15 nodes','20 nodes');
set(lg,'FontSize',14)
subplot(1,2,2);
lg = legend('No LTE - 1 node','No LTE - 2 nodes','No LTE - 3 nodes','No LTE - 4 nodes','  ABS 1 - 1 node','  ABS 1 - 2 nodes','  ABS 1 - 3 nodes','  ABS 1 - 4 nodes');
set(lg,'FontSize',14)

h1 = openfig(name1,'reuse'); % open figure
xlabel('Wi-Fi nodes','FontSize',14);
ylabel('Distribution (%)','FontSize',14);
title('Number of nodes per group - ABS1','FontSize',14);
lg = legend('  5 nodes','10 nodes','15 nodes','20 nodes');
set(lg,'FontSize',14)
grid minor

h2 = openfig(name2,'reuse'); % open figure
title('Average transmission time','FontSize',14);
xlabel('time (ms)','FontSize',14);
ylabel('ECDF','FontSize',14);
lg = legend('No LTE - 1 node','No LTE - 2 nodes','No LTE - 3 nodes','No LTE - 4 nodes','  ABS 1 - 1 node','  ABS 1 - 2 nodes','  ABS 1 - 3 nodes','  ABS 1 - 4 nodes');
set(lg,'FontSize',14)
grid minor;