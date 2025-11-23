# Script de nettoyage des dossiers obsolètes

Write-Host "🧹 Nettoyage des dossiers obsolètes..." -ForegroundColor Cyan
Write-Host ""

# Créer _archive s'il n'existe pas
if (-not (Test-Path "_archive")) {
    New-Item -ItemType Directory -Path "_archive" | Out-Null
}

# Liste des dossiers à archiver
$foldersToArchive = @(
    "Export excel",
    "fichier convertie"
)

foreach ($folder in $foldersToArchive) {
    if (Test-Path $folder) {
        $destination = Join-Path "_archive" $folder
        
        # Supprimer la destination si elle existe déjà
        if (Test-Path $destination) {
            Remove-Item $destination -Recurse -Force
        }
        
        # Copier puis supprimer
        Copy-Item $folder $destination -Recurse -Force
        Remove-Item $folder -Recurse -Force
        
        Write-Host "✅ '$folder' archivé" -ForegroundColor Green
    } else {
        Write-Host "⚠️ '$folder' introuvable" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📂 Dossiers restants:" -ForegroundColor Cyan
Get-ChildItem -Directory | Where-Object { $_.Name -ne "_archive" } | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host "✅ Nettoyage terminé!" -ForegroundColor Green
