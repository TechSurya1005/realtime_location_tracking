# Download Poppins fonts from Google Fonts GitHub
# Usage (from project root):
#   powershell -ExecutionPolicy Bypass -File .\scripts\download_poppins.ps1

$files = @(
  "Poppins-Thin.ttf",
  "Poppins-ExtraLight.ttf",
  "Poppins-Light.ttf",
  "Poppins-Regular.ttf",
  "Poppins-Medium.ttf",
  "Poppins-SemiBold.ttf",
  "Poppins-Bold.ttf",
  "Poppins-ExtraBold.ttf",
  "Poppins-Black.ttf"
)

$base = "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/"
$dest = "assets/fonts/poppins"

if (!(Test-Path $dest)) {
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

foreach ($f in $files) {
  $url = $base + $f
  $out = Join-Path $dest $f
  Write-Host "Downloading $f ..."
  try {
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -ErrorAction Stop
    Write-Host "  Saved to: $out"
  } catch {
    Write-Warning "  Failed to download $url -- check your internet connection or the URL."
  }
}

Write-Host "Done. Run 'flutter pub get' to register the new fonts."