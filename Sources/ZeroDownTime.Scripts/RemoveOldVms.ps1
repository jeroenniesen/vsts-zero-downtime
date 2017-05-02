#
# RemoveOldVms.ps1
#

Param(
  [string]$ResourceGroup,
  [string]$VmNamePrefix,
  [string]$AvailabilitySet
)


function Get-VMDisks($vm)
{
	#Function to get all disks attached to a VM
	$disks = @()
	$disks += ,$vm.StorageProfile.OsDisk.Vhd.Uri
	foreach ($disk in $vm.StorageProfile.DataDisks)
	{
		$disks += ,$disk.Vhd.Uri
	}
	return $disks
}
 
function Delete-Disk($uri)
{
	#Function to get delete disk and delete the container if it is empty
	$uriSplit = $uri.Split("/").Split(".")
	$saName = $uriSplit[2]
	$container = $uriSplit[$uriSplit.Length-3]
	$blob = $uriSplit[$uriSplit.Length-2] + ".vhd"
	$sa = Get-AzureRmStorageAccount | where {$_.StorageAccountName -eq $saName}
	$saKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $sa.ResourceGroupName -Name $sa.StorageAccountName).Value[0]
	$saContext = New-AzureStorageContext -StorageAccountName $sa.StorageAccountName -StorageAccountKey $saKey
	Remove-AzureStorageBlob -Blob $blob -Container $container -Context $saContext
 
	$remainingBlobs = Get-AzureStorageContainer -Name $container -Context $saContext | Get-AzureStorageBlob
 
	if ($remainingBlobs -eq $null)
	{
	Remove-AzureStorageContainer -Name $container -Context $saContext -Force
	}
}
 
function Get-VMNIC($vm)
{
	$nic = $vm.NetworkInterfaceIDs.split("/") | Select-Object -Last 1
	return $nic
}

$as = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroup -Name $AvailabilitySet
$vmrefs = $as.VirtualMachinesReferences

foreach($ref in $vmrefs) {
	if ($vm.Name -notlike ($vm_prefix + "*")) {
		$vm = Get-AzureRmResource -ResourceId $ref.id

		$disksToDelete = Get-VMDisks($vm)
		$nicToDelete = Get-VMNIC($vm)

		Write-Host "Deleting VM:" $vm.Name -ForegroundColor Yellow
		Remove-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force
		Write-Host "Deleting NIC:" $nicToDelete -ForegroundColor Yellow
		Remove-AzureRmNetworkInterface -Name $nicToDelete -ResourceGroupName $vm.ResourceGroupName -Force
		Write-Host "Deleting Disk:" $disk -ForegroundColor Yellow
		Delete-Disk($disk)
    } else {
        Write-Output "No VMs found!"
    }
}

