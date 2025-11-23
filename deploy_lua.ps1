# Script de déploiement du fichier Lua vers Windower
# Usage: .\deploy_lua.ps1

$source = "AltControl.lua"
$destination = "a:/Jeux/PlayOnline/Windower4/addons/AltControl/AltControl.lua"

Write-Host "📦 Déploiement de AltControl.lua vers Windower..." -ForegroundColor Cyan

if (Test-Path $source) {
    Copy-Item $source $destination -Force
    Write-Host "✅ Fichier copié avec succès!" -ForegroundColor Green
    Write-Host "💡 N'oubliez pas de recharger l'addon dans le jeu: //lua reload AltControl" -ForegroundColor Yellow
} else {
    Write-Host "❌ Erreur: $source introuvable!" -ForegroundColor Red
}
