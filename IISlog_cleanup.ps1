# Module: Powershell script to clean IIS log files
#http://www.codeproject.com/Articles/663000/Simple-Powershell-script-to-clean-up-IIS-log-files 
Set-Executionpolicy RemoteSigned
$days=-7 
(Get-Variable Path).Options="ReadOnly"
$Path="C:\inetpub\logs\LogFiles\W3SVC1"
Write-Host "Removing IIS-logs keeping last" $days "days"
CleanTempLogfiles($Path)

function CleanTempLogfiles()
{
param ($FilePath)
    Set-Location $FilePath
    Foreach ($File in Get-ChildItem -Path $FilePath)
    {
        if (!$File.PSIsContainerCopy) 
        {
            if ($File.LastWriteTime -lt ($(Get-Date).Adddays($days))) 

            {
            remove-item -path $File -force
            Write-Host "Removed logfile: "  $File
            }
    }
} 
}