<#
  PowerShell 7 Profile
  Marco Janse
  v2.8
  2023-08-12

  Version History:

  2.8 - Added some new functions and some housekeeping
  2.7 - Added/changed git variables for workdirs and formatting changes
  2.6 - Changed starting working dir and removed FormatEnumerationLimit settings
  2.5 - Added Get-DynamicParameters function
  2.4 - Updated Oh-My-Posh from PS module to the Winget package
  2.3 - Changed posh theme to slim
  2.2 - Cleaned up version
  2.1 - Minor reordering and tidy-up
  2.0 - Font and PoshGui theme changes + cleanup + uniformation
  1.1 - simplified the Get-Uptime function for modern PS and OS versions
  1.0 - Copied some things from my PowerShell 5.1 profile and added some stuff
        from other sources

 #>
 
 # Aliases #


 
 # Modules #
 
 # Functions #
 
  
   function Edit-HostsFile
   {
    param($ComputerName=$env:COMPUTERNAME)
   
    Start-Process notepad.exe -ArgumentList \\$ComputerName\admin$\System32\drivers\etc\hosts -Verb RunAs
   }
 

## Test SSL Protocols ##

<#
 .DESCRIPTION
   Outputs the SSL protocols that the client is able to successfully use to connect to a server.

 .NOTES

   Copyright 2014 Chris Duck
   http://blog.whatsupduck.net

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

 .PARAMETER ComputerName
   The name of the remote computer to connect to.

 .PARAMETER Port
   The remote port to connect to. The default is 443.

 .EXAMPLE
   Test-SslProtocols -ComputerName "www.google.com"

   ComputerName       : www.google.com
   Port               : 443
   KeyLength          : 2048
   SignatureAlgorithm : rsa-sha1
   Ssl2               : False
   Ssl3               : True
   Tls                : True
   Tls11              : True
   Tls12              : True
 #>
 function Test-SslProtocols {
  param(
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    $ComputerName,

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [int]$Port = 443
  )
  begin {
    $ProtocolNames = [System.Security.Authentication.SslProtocols] | Get-Member -static -MemberType Property | Where-Object {$_.Name -notin @("Default","None")} | ForEach-Object {$_.Name}
  }
  process {
    $ProtocolStatus = [Ordered]@{}
    $ProtocolStatus.Add("ComputerName", $ComputerName)
    $ProtocolStatus.Add("Port", $Port)
    $ProtocolStatus.Add("KeyLength", $null)
    $ProtocolStatus.Add("SignatureAlgorithm", $null)

    $ProtocolNames | ForEach-Object {
      $ProtocolName = $_
      $Socket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
      $Socket.Connect($ComputerName, $Port)
      try {
        $NetStream = New-Object System.Net.Sockets.NetworkStream($Socket, $true)
        $SslStream = New-Object System.Net.Security.SslStream($NetStream, $true)
        $SslStream.AuthenticateAsClient($ComputerName,  $null, $ProtocolName, $false )
        $RemoteCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]$SslStream.RemoteCertificate
        $ProtocolStatus["KeyLength"] = $RemoteCertificate.PublicKey.Key.KeySize
        $ProtocolStatus["SignatureAlgorithm"] = $RemoteCertificate.PublicKey.Key.SignatureAlgorithm.Split("#")[1]
        $ProtocolStatus.Add($ProtocolName, $true)
      } catch  {
        $ProtocolStatus.Add($ProtocolName, $false)
      } finally {
        $SslStream.Close()
      }
    }
    [PSCustomObject] $ProtocolStatus
  }
}

## Test SSL Protocols End ##

## Get-MailDomain Info
##
## By Harm Veenstra
## Source: https://github.com/HarmVeenstra/Powershellisfun/blob/main/Retrieve%20Email%20DNS%20Records/Get-MailDomainInfo.ps1
##

function Get-MailDomainInfo {
    param(
        [parameter(Mandatory = $true)][string[]]$DomainName,
        [parameter(Mandatory = $false)][string]$DNSserver
    )
     
    #Use DNS server 1.1.1.1 when parameter DNSserver is not used
    if (-not ($DNSserver)) {
        $DNSserver = '1.1.1.1'
    }

    $info = foreach ($domain in $DomainName) {
 
        #Retrieve all mail DNS records
        $autodiscoverA = (Resolve-DnsName -Name "autodiscover.$($domain)" -Type A -Server $DNSserver -ErrorAction SilentlyContinue).IPAddress
        $autodiscoverCNAME = (Resolve-DnsName -Name "autodiscover.$($domain)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue).NameHost
        $dkim1 = Resolve-DnsName -Name "selector1._domainkey.$($domain)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue
        $dkim2 = Resolve-DnsName -Name "selector2._domainkey.$($domain)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue
        $domaincheck = Resolve-DnsName -Name $domain -Server $DNSserver -ErrorAction SilentlyContinue
        $dmarc = (Resolve-DnsName -Name "_dmarc.$($domain)" -Type TXT -Server $DNSserver -ErrorAction SilentlyContinue | Where-Object Strings -Match 'DMARC').Strings
        $mx = (Resolve-DnsName -Name $domain -Type MX -Server $DNSserver -ErrorAction SilentlyContinue).NameExchange
        $spf = (Resolve-DnsName -Name $domain -Type TXT -Server $DNSserver -ErrorAction SilentlyContinue | Where-Object Strings -Match 'v=spf').Strings
 
        #Set variables to Not enabled or found if they can't be retrieved
        #and stop script if domaincheck is not valid 
        $errorfinding = 'Not enabled'
        if ($null -eq $domaincheck) {
            Write-Warning ("{0} not found" -f $domaincheck)
            return
        }
 
        if ($null -eq $dkim1 -and $null -eq $dkim2) {
            $dkim = $errorfinding
        }
        else {
            $dkim = "$($dkim1.Name) , $($dkim2.Name)"
        }
 
        if ($null -eq $dmarc) {
            $dmarc = $errorfinding
        }
 
        if ($null -eq $mx) {
            $mx = $errorfinding
        }
 
        if ($null -eq $spf) {
            $spf = $errorfinding
        }
 
        if (($autodiscoverA).count -gt 1) {
            $autodiscoverA = $errorfinding
        }
 
        if ($null -eq $autodiscoverCNAME) {
            $autodiscoverCNAME = $errorfinding
        }
 
        [PSCustomObject]@{
            'Domain Name'             = $domain
            'Autodiscover IP-Address' = $autodiscoverA
            'Autodiscover CNAME '     = $autodiscoverCNAME
            'DKIM Record'             = $dkim
            'DMARC Record'            = "$($dmarc)"
            'MX Record(s)'            = $mx -join ', '
            'SPF Record'              = "$($spf)"
        }
    }
         
    return $info
      
}

## Get-MailDomainInfo End

Import-Module Terminal-Icons

## PSReadline
Set-PSReadLineKeyHandler -Chord UpArrow -Function HistorySearchBackward
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView