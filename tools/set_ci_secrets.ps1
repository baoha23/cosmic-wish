# Set 3 secrets con lai cho CI tren GitHub repo baoha23/cosmic-wish:
#   SUPABASE_ANON_KEY, SUPABASE_ACCESS_TOKEN, SUPABASE_DB_PASSWORD
# Cach dung (chay tu thu muc goc du an):
#   powershell -File tools\set_ci_secrets.ps1
# Script tu lay GitHub token tu git credential roi hoi nhap tung gia tri.

$ErrorActionPreference = "Stop"
$repo = "baoha23/cosmic-wish"
$gh = "C:\Program Files\GitHub CLI\gh.exe"

if (-not (Test-Path $gh)) {
    Write-Host "LOI: khong tim thay gh.exe tai $gh" -ForegroundColor Red
    exit 1
}

# Git credential fill can stdin: protocol/host + dong trong cuoi.
# PowerShell day stdin vao exe qua pipeline bi loi nen dung
# Start-Process voi file redirect.
$tmpIn = New-TemporaryFile
$tmpOut = New-TemporaryFile
"protocol=https", "host=github.com", "" | Set-Content -Path $tmpIn -Encoding ascii
$p = Start-Process -FilePath git -ArgumentList "credential", "fill" `
    -RedirectStandardInput $tmpIn -RedirectStandardOutput $tmpOut `
    -NoNewWindow -Wait -PassThru
$token = (Get-Content $tmpOut |
    Where-Object { $_ -match '^password=(.+)$' } |
    ForEach-Object { $_ -replace '^password=', '' })
Remove-Item $tmpIn, $tmpOut -ErrorAction SilentlyContinue

if (-not $token) {
    Write-Host "LOI: khong lay duoc GitHub token tu git credential." -ForegroundColor Red
    exit 1
}
$env:GH_TOKEN = $token
Write-Host "Da lay GitHub token ✓" -ForegroundColor Green

function Set-Secret([string]$name) {
    Write-Host "`n== $name ==" -ForegroundColor Cyan
    $value = Read-Host "  Dan gia tri roi Enter"
    if ([string]::IsNullOrWhiteSpace($value)) {
        Write-Host "  Bo qua (rong)" -ForegroundColor Yellow
        return
    }
    $value | & $gh secret set $name --repo $repo
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  DA SET" -ForegroundColor Green
    } else {
        Write-Host "  LOI khi set" -ForegroundColor Red
    }
}

Write-Host "Se set 3 secrets cho repo $repo" -ForegroundColor Cyan
Set-Secret "SUPABASE_ANON_KEY"
Set-Secret "SUPABASE_ACCESS_TOKEN"
Set-Secret "SUPABASE_DB_PASSWORD"

Write-Host "`nDanh sach secrets hien co:" -ForegroundColor Cyan
& $gh secret list --repo $repo
