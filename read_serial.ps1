$port = New-Object System.IO.Ports.SerialPort "COM12", 115200, "None", 8, "One"
$port.DtrEnable = $false
$port.RtsEnable = $false
$port.ReadTimeout = 500
try {
    $port.Open()
    Write-Host "Connected without reset. Listening for 8 seconds..."
    $deadline = (Get-Date).AddSeconds(8)
    while ((Get-Date) -lt $deadline) {
        if ($port.BytesToRead -gt 0) {
            $data = $port.ReadExisting()
            Write-Host -NoNewline $data
        } else {
            Start-Sleep -Milliseconds 50
        }
    }
} finally {
    if ($port.IsOpen) {
        $port.Close()
    }
}
