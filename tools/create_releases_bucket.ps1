# Tao bucket public "releases" tren Supabase Storage (chay 1 lan).
# Cach dung:
#   powershell -File tools/create_releases_bucket.ps1 -ServiceRoleKey "eyJ..."
param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceRoleKey
)

$projectRef = "pjubjhrhyrtnnhavnkuk"
$bucket = @{
    name   = "releases"
    public = $true
}

try {
    $response = Invoke-RestMethod -Method Post `
        -Uri "https://$projectRef.supabase.co/storage/v1/bucket" `
        -Headers @{ "Authorization" = "Bearer $ServiceRoleKey" } `
        -ContentType "application/json" `
        -Body ($bucket | ConvertTo-Json)
    Write-Host "OK: bucket 'releases' da tao" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    # 409 = bucket da ton tai -> van coi nhu thanh cong
    if ($code -eq 409) {
        Write-Host "Bucket 'releases' da ton tai roi - OK" -ForegroundColor Green
    } else {
        # In them body loi that de chan doan chinh xac
        $detail = ""
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $detail = $reader.ReadToEnd()
        } catch {}
        Write-Host "LOI (HTTP $code): $($_.Exception.Message)" -ForegroundColor Red
        if ($detail) { Write-Host "Chi tiet: $detail" -ForegroundColor Red }
        exit 1
    }
}
