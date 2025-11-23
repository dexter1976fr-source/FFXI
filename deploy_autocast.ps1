# Script de déploiement AutoCast
# Copie les fichiers Lua vers Windower

$windowerPath = "A:\Jeux\PlayOnline\Windower4\addons\AltControl"

Write-Host "🚀 Déploiement AutoCast..." -ForegroundColor Cyan

# Copier les fichiers
Copy-Item "AutoCast.lua" -Destination "$windowerPath\AutoCast.lua" -Force
Write-Host "✅ AutoCast.lua copié" -ForegroundColor Green

Copy-Item "AutoCast_BRD.lua" -Destination "$windowerPath\AutoCast_BRD.lua" -Force
Write-Host "✅ AutoCast_BRD.lua copié" -ForegroundColor Green

Copy-Item "AltControl.lua" -Destination "$windowerPath\AltControl.lua" -Force
Write-Host "✅ AltControl.lua copié" -ForegroundColor Green

Write-Host ""
Write-Host "✨ Déploiement terminé!" -ForegroundColor Green
Write-Host "📝 Dans FFXI, tapez: //lua r AltControl" -ForegroundColor Yellow
