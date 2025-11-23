# 🚨 RESTAURATION RAPIDE - Double-clic sur ce fichier
# Restaure automatiquement les fichiers avant le split

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESTAURATION D'URGENCE ALTCONTROL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Trouver le dossier de backup
$backup = Get-ChildItem -Directory | Where-Object { $_.Name -like "BACKUP_BEFORE_SPLIT_*" } | Select-Object -First 1

if (-not $backup) {
    Write-Host "❌ ERREUR: Aucun backup trouvé!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Essayez la restauration Git:" -ForegroundColor Yellow
    Write-Host "  git checkout STABLE_BEFORE_SPLIT" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host "📁 Backup trouvé: $($backup.Name)" -ForegroundColor Green
Write-Host ""
Write-Host "Restauration en cours..." -ForegroundColor Yellow

try {
    # Restaurer AltControl.lua (projet)
    Copy-Item "$($backup.FullName)\AltControl.lua" "AltControl.lua" -Force
    Write-Host "✅ AltControl.lua (projet) restauré" -ForegroundColor Green
    
    # Restaurer AltControl.lua (Windower)
    Copy-Item "$($backup.FullName)\AltControl_Windower.lua" "A:\Jeux\PlayOnline\Windower4\addons\AltControl\AltControl.lua" -Force
    Write-Host "✅ AltControl.lua (Windower) restauré" -ForegroundColor Green
    
    # Restaurer FFXI_ALT_Control.py
    Copy-Item "$($backup.FullName)\FFXI_ALT_Control.py" "FFXI_ALT_Control.py" -Force
    Write-Host "✅ FFXI_ALT_Control.py restauré" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ RESTAURATION TERMINÉE!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prochaines étapes:" -ForegroundColor Cyan
    Write-Host "1. Dans FFXI, tapez: //lua r altcontrol" -ForegroundColor White
    Write-Host "2. Vérifiez que tout fonctionne: //ac status" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ ERREUR lors de la restauration:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
}

Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Gray
pause
