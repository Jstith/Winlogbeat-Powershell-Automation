## Installing Winlogbeat Agents on Windows 10 Endpoints

## What is it

Our Security Onion is configured to read network and host logs into the ELK (elasticsearch, logstash, kibana) software stack on the Security Onion box. `Winlogbeat` is a windows log aggregation service built by elastic to send windows logs to the ELK stack in Security Onion.

We have `Winlogbeat` agents installed on each windows 10 machine on the network. There is a service configured to run on startup called `winlogbeat`. The data for the service is stored in `C:\ProgramData\Elastic\Beats\winlogbeat\`.

## Installing the agents

### 1. Downoad and run Winlogbeat installer

Winlogbeat has an msi installer to install the agent on a windows computer. You can download the installer from https://www.elastic.co/downloads/beats/winlogbeat, and run it on the target endpoint.

### 2. Change the Outputs from Elasticsearch to Logstash

The default installation of winlogbeat has some incorrect settings in its configuration file, `winlogbeat.yml` for Security Onion **(winlogbeat is automatically setup to run with the default configuration of ELK stack, not the confguration Security Onion uses)**. To properly modify the configuration file for Security Onion, the following changes have to be made:

Comment out the following lines in the Elasticsearch Output section: 
*     output.elasticsearch:
*     hosts: ["127.0.0.1:9200"]

Uncomment the following lines:
*     output.logstash
*     hosts ["127.0.0.1:5044"]
### 3. Change the target IP of Logstash to Security Onion Box

Change the Logstash hosts line in the Logstash Output section:
*     hosts: ["127.0.0.1:5044"] --> hosts: ["<IP_SECURITY_ONION>:5044"]

### 4. Move configuration file to correct directory

Name the modified file `winlogbeat.yml` and store in at `C:\ProgramData\Elastic\Beats\winlogbeat\winlogbeat.yml`.

### 5. Start the Winlogbeat service

In powershell, run the following command:

```powershell
PS> Start-Service winlogbeat
```
## Network Distribution

### Enable WinRM

To install the winlogbeat agents across the network without internet access, we used powershell scripting to move the installer and configuration file across the network. To do this, we needed to enable `WinRM` to use remote powershell sessions. This can be done in a few different ways:

1. With a PowerShell CimSession from a Domain Admin
* See enable_remoting script

2. With Group Policy (better option if targeting entire network)

* Many tutorials out there, we used: https://www.youtube.com/watch?v=zVMGal0MpSA
* Once configured, you can push the group policy out to all computers on the network from the Domain Controller (or any machine with GPMC)

![](https://i.imgur.com/wFcz4IJ.png)

### Install winlogbeat agent via PowerShell

This repository contains a couple of different scripts for installing agents on a windows host remotely following the above steps in powershell.

* `remote_log`
