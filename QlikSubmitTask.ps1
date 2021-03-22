    
    
param(
    [string] $serverUrl = "https://srvtst.acme.com",
    [string] $QlikUser = "user@domain",
    [string] $TaskId = "xxxxxxxxx-xxxx-xxxx-xxx-xxxxxxxxxxxx",
    [int] $PollingInterval = 5
    )


function Ignore-SelfSignedCerts {
    add-type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

function LogConsole($string)
{
   
   $TimeStamp = (Get-date -Format dd-MM-yyyy) + " " + (get-date -format HHMMsstt) 
   $TimeStamp += " " + $string 

   write-host $TimeStamp
}

function Invoke-QlikRestMethod {
    param(
        [ValidateNotNullorEmpty()]
        [String]$Uri,
        [ValidateNotNullorEmpty()]
        [String]$Method,
        [object]$Body = $null
    )

    $uriFull = $Global:QlikProxyRESTApiUrl + $Uri
    
    #LogConsole ( "Sending Web Request... : $($uriFull)")

    try
    {
        if ($null -eq $Body)
        {
            $response = Invoke-RestMethod -Method $Method -Uri $uriFull -Headers $Global:QlikRESTApiAuthHeader -ErrorVariable $RestException
        }
        else
        {
            $Body = ConvertTo-Json $Body -Depth 99
            $response = Invoke-RestMethod -Method $Method -Uri $uriFull -Headers $Global:QlikRESTApiAuthHeader -Body $Body -ContentType 'application/json; charset=utf-8' -ErrorVariable $RestException
        }
        return $response
    }
    catch
    {
        Write-Warning ("Error")
        Write-Warning ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
        Write-Warning ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        Write-Warning ("Message: " + $_.Exception.Message)
        
        throw
        ##exit $_.Exception.Response.StatusCode.value__
    }
}

function Get-QlikApiAuthHeader {
    param(
        [string] $Token
        )
        $authHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $authHeader.Add("X-Qlik-xrfkey", ("ABCDEFG123456789"))
        $authHeader.Add("opcon-usr", ($QlikUser))
        
        return $authHeader
    }
    
    function Initial-Setup {
        [cmdletbinding()]
        param(
            [string] $serverUrl ,
	        [string] $QlikUser 
            )
            LogConsole ("")
            LogConsole ("*********************************************************")
            LogConsole ("  OpCon Start Task on Qlik")
            LogConsole ("  QlikUser            : " + $QlikUser)
            
            $serverUrl = $serverUrl.ToLower().TrimEnd("/")
            $serverUrl = -join($serverUrl, "/opcon/qrs")
        
            LogConsole ("  Qlik API server url : " + $serverUrl)
            LogConsole ("  Polling interval    : " + $PollingInterval)
            LogConsole ("  TaskID              : " + $TaskId)
            
            LogConsole ("*********************************************************")
            
            $Global:QlikProxyRESTApiUrl = $serverUrl
        
            $Global:QlikRESTApiAuthHeader = Get-QlikApiAuthHeader 
            
        } 
 
 function GetQlikAboutInfo
 {
 [cmdletbinding()]
 param( )
 
        LogConsole ("Get Infos from Qlik Server")
      
        

        $infoUri = "/about?xrfkey=ABCDEFG123456789"
        $response = Invoke-QlikRestMethod -Uri $infoUri -Method GET -ContentType "application/json"
        
        LogConsole ($response)
        
}


function SubmitQlikTaskAndGetSessionID
{
[cmdletbinding()]
param( [string] $TaskID )

       LogConsole ("Submit Task : $($TaskID) and retrieve SessionID")
       $sessionID = ""
     
       try
       {
        
           $infoUri = "/task/" + $TaskID + "/start/synchronous/?xrfkey=ABCDEFG123456789"
           #LogConsole ($infoUri)
           $response = Invoke-QlikRestMethod -Uri $infoUri -Method POST -ContentType "application/json"-Headers $Global:QlikRESTApiAuthHeader 
           
           #$response = Invoke-QlikRestMethod -Uri $infoUri -Method GET -ContentType "application/json"

           $sessionID = $response.value
           
           
       }
       catch {
            LogConsole ( "Problem on Tasks' submission")
            Exit 100;
       }
       return  $sessionID
}

function CheckTaskSessionStatus 
{
[cmdletbinding()]
param( [string] $SessionID )

       LogConsole ("Check Status for Session: $($SessionID)")
       $bCompleted = $false;
       $bExitCode = 1;

        do {
            try
            {
                $infoUri = "/executionresult?filter=ExecutionId eq $($SessionID) &xrfkey=ABCDEFG123456789"
                $response = Invoke-QlikRestMethod -Uri $infoUri -Method GET -ContentType "application/json"-Headers $Global:QlikRESTApiAuthHeader -ErrorVariable $RestException; 
                
                
                switch ( $response.status )
                {
                    0 { $result = 'NeverStarted'    }
                    1 { $result = 'Triggered'    }
                    2 { $result = 'Started'   }
                    3 { $result = 'Queued' }
                    4 { $result = 'AbortInitiated'  }
                    5 { $result = 'Aborting'  }
                    6 { $result = 'Aborted' 
                            $bCompleted = $true }
                    7 { 
                            $result = 'FinishedSuccess'  
                            $bCompleted = $true 
                            $bExitCode = 0;
                    }
                    8 {     
                            $result = 'FinishedFail' 
                            $bCompleted = $true
                    }
                    9 { $result = 'Skipped'  }
                    10 { $result = 'Retry'  }
                    11 { $result = 'Error' 
                            $bCompleted = $true }
                    12 { $result = 'Reset' 
                            $bCompleted = $true }
                   
                }
                LogConsole ("SessionID: $($SessionID) -> Job Status: $($result)" )

            }
            catch {
                LogConsole ( "SessionID: $($SessionID) Problems while checking job stasut, exiting 100")
                 Exit 100;
            }    
            if ($bCompleted -eq $false) {
                Start-Sleep -s $PollingInterval    
            }  
            
        } while ($bCompleted -eq $false)
    return $bExitCode;
}



# Initial Setup
Initial-Setup -serverUrl $serverUrl -QlikUser $QlikUser

# Check for connectivity
#GetQlikAboutInfo

# Task Submission
Ignore-SelfSignedCerts
$sSessID= ""
$sSessID = SubmitQlikTaskAndGetSessionID  -TaskID $TaskId
if ($sSessID.Length -gt 0 ){
    $exitCode = CheckTaskSessionStatus -SessionID $sSessID
    LogConsole ( "Exiting from Task Submission e Check Running :$($exitCode)")

}

