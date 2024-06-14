# SELDAT

<div>
<!--	<a href = "홈페이지url" target="_blank"> -->
	<p align = "center">
<!-- 	  <img src = "https://github.com/seslabSJU/tinyIoT/assets/136944859/5d107ae0-40f9-480e-8309-eba805223906" width = "40%" height = "50%"> -->
	</p></a>
</div>

<p align = "center"> Analyze Windows Artifacts Anomaly Quickly </p> <br>
<p align = "center"> <img src="https://img.shields.io/badge/windows-%230078D6.svg?&style=for-the-badge&logo=windows&logoColor=white" />&nbsp 
<img src="https://img.shields.io/badge/sqlite-%23003B57.svg?&style=for-the-badge&logo=sqlite&logoColor=white" />&nbsp
<img src="https://img.shields.io/badge/flutter-%2302569B.svg?&style=for-the-badge&logo=flutter&logoColor=white" />&nbsp
 </p>
<br><br>


# What is the Seldat?

<b>SELDAT</b> is a tool to collect Windows artifacts such as EventLog, SRUM, Prefetch etc.
<br />
It analyzes artifact and show abnormal behaviors to reduce time consumption of the user.
<br />
It uses <b>Artificial Inteligence</b> for Anomaly Detection, while using Sigmal rule to detect malicious behaviors.
<br />
It scans windows registry and see if any trace of malware exists.
<br>

<img width="800" alt="image" src="https://github.com/LAMXkE/Seldat/assets/39945981/243958bd-16b7-45ea-87c5-8d70d2763377">

# Artifacts Collected
- Windows EventLog
- SRUM
- Prefetch
- Jumplist
- Registry

# Usage

Download From Release and Execute it with Administrator Privilege
<br />
1-1. Start Scanning Computer
<img width="800" alt="image" src="https://github.com/LAMXkE/Seldat/assets/39945981/08441021-2527-4fba-942c-eca8fcbb4b6f">
<br />
1-2. Load From Database
<br />
<img width="800" alt="image" src="https://github.com/LAMXkE/Seldat/assets/39945981/129b7a60-8763-42c7-96de-2b021f20a26b">
<br />
2. Wait Until Loaded/Scanned
<br />

# Tool UI
## Event Logs
![image](https://github.com/LAMXkE/Seldat/assets/39945981/cd54423d-7e7d-4629-a2a0-5834ec693280)
<br />
Click each Logs to see details
<br />
Click File name to read single event log file
<br />
Filter logs with content, timestamp, anomaly
## Registry
![image](https://github.com/LAMXkE/Seldat/assets/39945981/ce1216b2-79f2-4830-b4d9-6f056c83e2a2)
## SRUM, Prefech, Jumplist
![image](https://github.com/LAMXkE/Seldat/assets/39945981/984375ef-fc5e-4ce4-813e-a995b8320d52)

# External Tools

- <a href="https://github.com/EricZimmerman/Srum">SrumECmd</a>
- <a href="https://www.nirsoft.net/utils/win_prefetch_view.html">WinPrefetchView</a>
- <a href="https://www.nirsoft.net/utils/jump_lists_view.html">JumpListsView</a>
- <a href="https://github.com/omerbenamram/evtx">evtxDump</a>
