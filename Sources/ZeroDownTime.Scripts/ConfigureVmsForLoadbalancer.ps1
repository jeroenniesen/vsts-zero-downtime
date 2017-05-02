#
# ConfigureLoadBalancer.ps1
#

Param(
  [string]$LoadBalancerName,
  [string]$LoadBalancerResourceGroup,
  [string]$LoadBalancerBackendName,  
  [string]$VmResourceGroup,
  [string]$NicPrefix,
  [int]$Instances
)


$lb= get-azurermloadbalancer -name $LoadBalancerName -resourcegroupname $LoadBalancerResourceGroup
$backend=Get-AzureRmLoadBalancerBackendAddressPoolConfig -name $LoadBalancerBackendName -LoadBalancer $lb


for($i=1; $i -lt $Instances; $i++){
	$nicname = $NicPrefix + $i
	Write-Host ("Configuring NIC: " + $nicname)
	
	$nic =get-azurermnetworkinterface -name $nicname -resourcegroupname $VmResourceGroup
	$nic.IpConfigurations[0].LoadBalancerBackendAddressPools=$backend
	
	Set-AzureRmNetworkInterface -NetworkInterface $nic
}