## Introduction

This code simulates the Distributed Coordination Function (DCF) included in most 802.11 devices operating in the sub-6 GHz band. That is, employing Carrier sensing mechanisms (i.e. CSMA/CA) to detect channel availability and backoff (i.e. exponential window size backoff) to defer transmissions and allow for a fair channel access in the unlicensed band.

The aim of this project is to implement a Matlab Medium Access Control (MAC) based on the DCF and understand how parameters such as the number of nodes contending for the channel or the presence of an external interference (i.e. LTE in the unlicensed band) affect the WiFi performance. The code provides metrics such as:
1. **Channel Busy Rate**: The portion of time that the channel is sensed busy due to other ongoing WiFi transmissions or external interference.
2. **Packets transmitted**: Number of packets that made it across the channel without experiencing a collision.
3. **Collisions**: Number of packets that need to be retransmitted due to collision with other WiFi node.
4. **Packet transmit time**: The average time in milliseconds that takes a WiFi node to access the channel and succesfully transmit a packet without colliding with any other node in the network.
 
The deployment scenario conceives *N* WiFi devices deployed in the area, all of them being in range of everyone else, and with no RTS/CTS mechanism enabled. That is, a WiFi transmission always causes the Sensing Mechanisms to detect the channel busy at every node in the network.

## Project hierarchy

The project is organized as follows:

1. **Data** (The files in the folder */DATA* contain the external interference that are considered in the experiments. The files *lteInput_ABS\*.m* contain the LTE interference when subframes 0, 1 and 5 are configured as Almost Blank Subframes (ABS) to allow for WiFi transmissions.
2. **contendWiFiLTE_runnable.m**: This is the main script that loads the WiFi configuration and the external LTE interference. The code calls *fcontend_WiFiLTE.m* to simulate the contention scenario and, once done, it calls *contendWiFiLTE_plot.m* to visualize the results. The results are stored in an intermediate variable (*DATA/lastResults*) as to split up execution and visualization.
2. **contendWiFiLTE_plot.m**: Visualization script that plots the results from the *contendWiFiLTE_runnable.m*
3. **fcontend_WiFiLTE.m**: Main script that simulates the contention scenario as a Discrete-Event-Simulator (DES), where each event is a time slot and each node switch from three different states: DIFS (waiting fixed DIFS time), TX (transmitting packet during the current slot) or BO (Backoff time). The nodes operate in saturation mode (i.e. always having a packet to be transmitted in their queue) and switch their states throughout the simulation.

## Contact

Please, feel free to contact me for any questions or concerns you may have at:

Carlos Bocanegra Guerra  
PhD Candidate  
Electrical and Computer Engineering (EECE)  
Northeastern University  
bocanegrac@coe.neu.edu