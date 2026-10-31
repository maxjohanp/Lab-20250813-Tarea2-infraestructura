# =============================================================================
#  limpiar-secretos.ps1 · quita claves y hashes de los running-config antes de subirlos
#  Seguridad de Redes · Tarea AAA · Maxyohan Montas (2025-0813)
#
#  Se ejecuta en TU PC, dentro de la carpeta del repositorio:
#    powershell -ExecutionPolicy Bypass -File scripts\limpiar-secretos.ps1 configs\*_running-config.txt
#
#  Cambia por <ELIMINADO> lo que va después de:
#    enable secret / enable secret level N      (hash de cada nivel)
#    username ... secret                         (hash del usuario local)
#    key ...                                     (secreto RADIUS, tipo 7 = reversible)
#  Al final avisa si queda alguna línea sospechosa para revisarla a mano.
# =============================================================================
param([Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)][string[]]$Archivos)

foreach ($a in (Get-ChildItem -Path $Archivos -File | Select-Object -ExpandProperty FullName)) {
    $lineas = Get-Content -LiteralPath $a
    $limpias = foreach ($l in $lineas) {
        $l -replace '^(\s*enable (secret|password)( level \d+)?( \d+)? )\S+.*$', '$1<ELIMINADO>' `
           -replace '^(\s*username \S+ .*?(secret|password)( \d+)? )\S+.*$', '$1<ELIMINADO>' `
           -replace '^(.*\skey( \d+)? )\S+.*$', '$1<ELIMINADO>'
    }
    Set-Content -LiteralPath $a -Value $limpias -Encoding UTF8
    $quedan = $limpias | Where-Object { $_ -match '\b(secret|password|key) ' -and $_ -notmatch '<ELIMINADO>$' }
    if ($quedan) {
        Write-Warning "Revisa a mano estas líneas de ${a}:"
        $quedan | ForEach-Object { '   ' + $_ }
    } else {
        Write-Host "OK · $a sin secretos"
    }
}
