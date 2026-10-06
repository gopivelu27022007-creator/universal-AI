$port = 8080
$ip = [System.Net.IPAddress]::Any
$listener = New-Object System.Net.Sockets.TcpListener($ip, $port)

try {
    $listener.Start()
    Write-Host "=========================================="
    Write-Host "  Universal AI Chatbot is running at:"
    Write-Host "  http://localhost:$port"
    Write-Host "=========================================="
    Start-Process "http://localhost:$port"
} catch {
    Write-Host "Error starting listener on port $port : $_"
    exit 1
}

$root = (Get-Item .).FullName

while ($true) {
    try {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $buffer = New-Object byte[] 4096
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)

        if ($bytesRead -gt 0) {
            $requestText = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)
            $firstLine = $requestText.Split("`r`n")[0]
            $parts = $firstLine.Split(" ")

            if ($parts.Length -ge 2) {
                $rawPath = $parts[1]
                $cleanPath = $rawPath.Split("?")[0].TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
                if ([string]::IsNullOrWhiteSpace($cleanPath)) {
                    $cleanPath = "index.html"
                }

                $fullPath = Join-Path $root $cleanPath

                if (Test-Path $fullPath -PathType Leaf) {
                    $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
                    $contentType = switch ($ext) {
                        ".html" { "text/html; charset=utf-8" }
                        ".css"  { "text/css; charset=utf-8" }
                        ".js"   { "application/javascript; charset=utf-8" }
                        ".json" { "application/json; charset=utf-8" }
                        ".svg"  { "image/svg+xml" }
                        ".png"  { "image/png" }
                        ".jpg"  { "image/jpeg" }
                        ".ico"  { "image/x-icon" }
                        default { "application/octet-stream" }
                    }

                    $content = [System.IO.File]::ReadAllBytes($fullPath)
                    $header = "HTTP/1.1 200 OK`r`n" +
                              "Content-Type: $contentType`r`n" +
                              "Content-Length: $($content.Length)`r`n" +
                              "Access-Control-Allow-Origin: *`r`n" +
                              "Connection: close`r`n`r`n"
                    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($headerBytes, 0, $headerBytes.Length)
                    $stream.Write($content, 0, $content.Length)
                } else {
                    $notFound = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: 13`r`nConnection: close`r`n`r`n404 Not Found"
                    $notFoundBytes = [System.Text.Encoding]::UTF8.GetBytes($notFound)
                    $stream.Write($notFoundBytes, 0, $notFoundBytes.Length)
                }
            }
        }
        $stream.Close()
        $client.Close()
    } catch {
        # ignore drop
    }
}
