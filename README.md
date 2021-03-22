# QlikSense Tasks - Powershell
This scripts submits a QlickSense ETL Task on a Qlik Sense Scheduler Service (QSS).

The script submits the Task and then polls for the status until the completion.

# Disclaimer
No Support and No Warranty are provided by SMA Technologies for this project and related material. The use of this project's files is on your own risk.

SMA Technologies assumes no liability for damage caused by the usage of any of the files offered here via this Github repository.

# Prerequisites

* Powershell v5.1
* QlikSense server environment with the API exposed via Virtual Proxy
* Qlik Authenticating with an HTTP header. <a href url="https://help.qlik.com/en-US/sense-developer/June2019/Subsystems/RepositoryServiceAPI/Content/Sense_RepositoryServiceAPI/RepositoryServiceAPI-Connect-API-Authenticate-Reqs.htm#anchor-3">Qlick, Authenticating with an HTTP header and virtual proxy</a>

# Instructions

  * <b>ServerUrl</b> - Qlik Server address
  * <b>QlikUser</b> - Qlik user with rights to execute Qlik Api via virtual proxy.
  * <b>TaskId</b> - Unique ID of a Qlik Task
  * <b>PollingInterval</b> - Refresh interval for status polling 
  
Example:
```
powershell.exe -ExecutionPolicy Bypass -File "C:\QlikSubmitTask.ps1" -serverUrl "https://srvtst.acme.com" -QlikUser "user@acme.com" -TaskId "xxxxxxxxx-xxxx-xxxx-xxx-xxxxxxxxxxxx" -PollingInterval 5

```  
<b>Script exit code:</b>
  * 0 = Script executed correclty, Task submitted and tracked, see below for Qlik Task completion status
  * 100 = Error in Task submission, Task is not submitted
  * Not 0 = Other errors


<b>Qlik Task all  possibile status (logged):</b>

0='NeverStarted', 1='Triggered', 2='Started', 3='Queued', 4='AbortInitiated', 5='Aborting', 6='Aborted', 7='FinishedSuccess', 8='FinishedFail', 9='Skipped', 10='Retry', 11='Error', 12='Reset'

<b>Qlik Task Completion Status (Failure):</b>

6='Aborted', 8='FinishedFail', 11='Error', 12='Reset'

<b>Qlik Task Completion Status (Success):</b>

7='FinishedSuccess'

# License
Copyright 2019 SMA Technologies

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

# Contributing
We love contributions, please read our [Contribution Guide](CONTRIBUTING.md) to get started!

# Code of Conduct
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code-of-conduct.md)
SMA Technologies has adopted the [Contributor Covenant](CODE_OF_CONDUCT.md) as its Code of Conduct, and we expect project participants to adhere to it. Please read the [full text](CODE_OF_CONDUCT.md) so that you can understand what actions will and will not be tolerated.
