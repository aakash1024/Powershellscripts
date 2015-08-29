Remove-Item C:\PatchDatabase\DED14AP502.tycoelectronics.net.csv -Force
Remove-Item C:\PatchDatabase\US194MN10.us.tycoelectronics.com.csv -Force
Remove-Item C:\PatchDatabase\JPD91MN001.tycoelectronics.net.csv -Force
Remove-Item C:\PatchDatabase\SrvComp\Critical\CriticalPatchServers\*.csv -Force
$WSUServers = Get-Content C:\PatchDatabase\WSUSServer.txt

foreach($WSUSServer in $WSUServers)
{
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$global:wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($WSUSServer,$False,8530)
$computerscope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computerScope.IncludedInstallationStates = [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::InstalledPendingReboot
$updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$a = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$b = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$c =  $wsus.getcomputertargets($a)
$k = $wsus.GetSummariesPerComputerTarget($b,$a)
$k | ForEach {New-Object PSobject -Property @{
ComputerTarget = ($wsus.GetComputerTarget([guid]$_.ComputerTargetId)).FullDomainName
DownloadedCount = $_.DownloadedCount
FaliedCount = $_.FailedCount
RebootPending = $_.installedpendingrebootcount
}} | Export-Csv C:\PatchDatabase\"$Wsusserver.csv" -NoClobber -Force -NoTypeInformation
}


Remove-Item C:\PatchDatabase\SrvComp\*.csv -Force
$items = Get-Item C:\PatchDatabase\*.csv
foreach($item in $items)
{
$a=$item.name
$k=@()
Import-Csv $item | %{
if((!($_.DownloadedCount -eq 0))-or(!($_.FaliedCount -eq 0)))
{
$k+= ,($_.ComputerTarget+'='+$_.DownloadedCount+'='+$_.FaliedCount)
}
}
$k | Out-File C:\PatchDatabase\SrvComp\"$a" -Encoding ASCII -Force
$k="";
}

Remove-Item C:\PatchDatabase\SrvComp\Critical\*.csv -Force
$CPS = Get-Item C:\PatchDatabase\SrvComp\*.csv

foreach($CP in $CPS)
{
if($CP.Name -like "JPD91MN001*")
{
$WS = "JPD91MN001.tycoelectronics.net"
}
elseif($CP.Name -like "DED14AP502*")
{
$WS = "DED14AP502.tycoelectronics.net"
}
elseif($CP.Name -like "US194MN10*")
{
$WS = "US194MN10.us.tycoelectronics.com"
}
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$global:wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($WS,$False,8530)
$computerscope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$a = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$b = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$c =  $wsus.getcomputertargets($a)
$o = $wsus.GetSummariesPerComputerTarget($b,$a)

$computer1 = Import-Csv C:\PatchDatabase\SrvComp\$($CP.Name) -Header server | Select-Object server -ExpandProperty server
$Computer=  $Computer1 | %{$_ -split "=" | select-object -index 0}

$RemoteComputer =@()
ForEach($Comp in $computer)
{
$neededUpdates = ($WSUS.GetComputerTargetbyname($Comp)).GetUpdateInstallationInfoPerUpdate() | `
                ?{($_.UpdateApprovalAction -eq "install") -and (($_.UpdateInstallationState -eq "downloaded") -or ($_.UpdateInstallationState -eq "notinstalled"))}
if ($neededUpdates -ne $null)
                {
                    foreach ($update in $neededUpdates)
                    {
                        $updateMeta = $wsus.GetUpdate([Guid]$update.updateid)
                                    if($updateMeta.UpdateClassificationTitle -eq "Critical Updates")
                                    {
                                    $RemoteComputer+=$Comp;
                                    
                                    }
                       }

}
}
$R = @()
$RemoteComputer = $remotecomputer | select -Unique
if($($CP.name) -like "JPD91*")
{
$region1 = "APAC"
$RemoteComputer | Out-File C:\PatchDatabase\SrvComp\Critical\CriticalPatchServers\$($Cp.name)
}
elseif($Cp.Name -like "US*")
{
$region1 = "AMERICAS"
$RemoteComputer | Out-File C:\PatchDatabase\SrvComp\Critical\CriticalPatchServers\$($Cp.name)
}
elseif($CP.Name -like "DE*")
{
$region1 = "EMEA"
$RemoteComputer | Out-File C:\PatchDatabase\SrvComp\Critical\CriticalPatchServers\$($Cp.name)
}


$R+=New-Object psObject -Property @{
                                                      'Region' = $region1
                                                      'TotalServers' = $o.count
                                                   'ComplaintSystem'=  $($o.count - $remotecomputer.count)
                                                   'NonCompliantSystem' = $RemoteComputer.Count
                                                   'PercentageNonCompliant' = $(($RemoteComputer.count*100)/$o.count)
                                                      } |Select-Object Region,TotalServers,ComplaintSystem,NonCompliantSystem,PercentageNonCompliant
            $R | Export-Csv C:\PatchDatabase\SrvComp\Critical\$($CP.Name) -NoTypeInformation 
            $R="";

}
