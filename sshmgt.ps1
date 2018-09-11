#requires -version 2
<#
.SYNOPSIS
  SSH Management Script. Allows enterprise scale organized SSH user management.
.DESCRIPTION
  Stores user information in powershell config file. Located C:\Scripts\Config\sshmgt.psd1
  This script requires Posh-SSH
.PARAMETER <Parameter_Name>
    -u UserName is the User this command is being sent to.
    -c Command is the Command being sent
.INPUTS
  None
.OUTPUTS
  Config file stored C:\Scripts\Config\sshmgt.psd1
.NOTES
  Version:        1.0
  Author:         Ryan Bowen
  Creation Date:  09/11/2018
  Purpose/Change: Initial script development
.EXAMPLE
  .\sshmgt.ps1 -u fbar -c "restart"
#>

##################
# Initialisation #
##################

Param(
    [Parameter(Mandatory=$true)][string]$UserName,
    [Parameter(Mandatory=$true)][string]$Command
    )

$ErrorActionPreference = "Continue"


################
# Declarations #
################

# Configuration File
$cfg = 'C:\Scripts\Config'

# If Configuration file not present. Create with Administrator credentials.
if ($(Test-Path -Path $cfg\sshmgt.psd1) -eq ($false))
    {
    [string]$admin = $(Read-Host -Prompt "Please enter the Administrator account [Administrator]")
    if (!$admin)
        {
        [string]$admin = 'Administrator'
        }
    $pwd = $(Read-Host -Prompt "Please enter the Administrator Password" -AsSecureString | ConvertFrom-SecureString)
@"
@{
Admin = "$admin"
Password = "$pwd"
}
"@ | Out-File -FilePath $cfg\sshmgt.psd1
    }

# Import configuration file
Import-LocalizedData -BindingVariable "Config" -BaseDirectory $cfg -FileName sshmgt.psd1

$srvname = "SRV$UserName"
# Test if the variable is present, If not create record of users IP
if ($Config.$srvname -eq $null)
    {
    $srv = $(Read-Host -Prompt "Please enter the Local IP Address of the users machine.")
@"
@{
$srvname = "$srv"
}
"@ | Out-File -FilePath $cfg\sshmgt.psd1 -Append
    Import-LocalizedData -BindingVariable "Config" -BaseDirectory $cfg -FileName sshmgt.psd1
    }

# Retrives credentials from config file
$pwd = $Config.Password | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential ($Config.Admin, $pwd)

#############
# Execution #
#############

# Exits any ongoing SSH Sessions
Get-SSHSession | Remove-SSHSession

# Creates new SSH session with stored credentials
New-SSHSession -ComputerName $Config.$srvname -Credential $cred

# Invokes SSH Command
Invoke-SSHCommand -Command $Command -SessionId 0

# Exits any ongoing SSH Sessions
Get-SSHSession | Remove-SSHSession
