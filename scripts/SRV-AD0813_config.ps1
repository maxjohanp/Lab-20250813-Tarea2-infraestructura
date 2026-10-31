﻿# =============================================================================
#  SRV-AD0813 · Windows Server 2022 · AD DS + DNS + NPS (servidor RADIUS)
#  Seguridad de Redes · Tarea AAA · Maxyohan Montas (2025-0813)
#
#  Se usa POR PARTES y en orden (1 a 6): copia un bloque "& { ... }" completo,
#  pégalo en Windows PowerShell (Admin) del servidor y pulsa Enter.
#  Las partes 1 y 2 reinician el servidor. La 7 es para después de las pruebas.
#  Las contraseñas y el secreto RADIUS se escriben cuando el bloque los pide:
#  no quedan en este archivo, ni en el historial, ni en el repositorio.
# =============================================================================
if ($MyInvocation.MyCommand.Path) {
    Write-Warning 'Este archivo no se ejecuta completo: copia y pega cada parte en PowerShell (Admin).'
    return
}

# --- Parte 1 · Red, nombre, hora y ping (reinicia al final) -------------------
& {
    $nic = 'Ethernet'
    Get-NetAdapter -Name $nic -ErrorAction Stop | Out-Null
    Set-NetIPInterface -InterfaceAlias $nic -AddressFamily IPv4 -Dhcp Disabled
    Get-NetIPAddress -InterfaceAlias $nic -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    Get-NetRoute -InterfaceAlias $nic -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $nic -IPAddress 10.20.25.10 -PrefixLength 24 -DefaultGateway 10.20.25.1 | Out-Null
    Set-DnsClientServerAddress -InterfaceAlias $nic -ServerAddresses 10.20.25.10
    Set-TimeZone -Id 'SA Western Standard Time'
    Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In
    Get-NetIPConfiguration -InterfaceAlias $nic
    Write-Host 'Listo. Se reinicia como SRV-AD0813 en 15 segundos.' -ForegroundColor Green
    Start-Sleep -Seconds 15
    Rename-Computer -NewName SRV-AD0813 -Restart -Force
}

# --- Parte 2 · Active Directory: bosque lab0813.local (reinicia solo) ---------
& {
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    $dsrm = Read-Host -AsSecureString 'Clave DSRM (restauración de AD)'
    $bosque = @{
        DomainName = 'lab0813.local'; DomainNetbiosName = 'LAB0813'; InstallDns = $true
        SafeModeAdministratorPassword = $dsrm; Force = $true
    }
    Install-ADDSForest @bosque
}

# --- Parte 3 · OU AAA-Redes, grupos de nivel 0, 5 y 10 y un usuario en cada uno
& {
    $dominio = Get-ADDomain -ErrorAction Stop
    $ou = "OU=AAA-Redes,$($dominio.DistinguishedName)"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'AAA-Redes'")) {
        New-ADOrganizationalUnit -Name 'AAA-Redes' -Path $dominio.DistinguishedName -Description 'Acceso a equipos Cisco por RADIUS'
    }
    $niveles = @(
        @{ Grupo = 'GRP-NIVEL-0';  Usuario = 'invitado0813'; Nombre = 'Invitado'; Apellido = 'Nivel 0';  Nivel = 0 },
        @{ Grupo = 'GRP-NIVEL-5';  Usuario = 'soporte0813';  Nombre = 'Soporte';  Apellido = 'Nivel 5';  Nivel = 5 },
        @{ Grupo = 'GRP-NIVEL-10'; Usuario = 'operador0813'; Nombre = 'Operador'; Apellido = 'Nivel 10'; Nivel = 10 }
    )
    foreach ($n in $niveles) {
        if (-not (Get-ADGroup -Filter "Name -eq '$($n.Grupo)'")) {
            New-ADGroup -Name $n.Grupo -GroupScope Global -GroupCategory Security -Path $ou -Description "Cisco privilege level $($n.Nivel)"
        }
        if (-not (Get-ADUser -Filter "SamAccountName -eq '$($n.Usuario)'")) {
            $usuario = @{
                Name = "$($n.Nombre) $($n.Apellido)"; GivenName = $n.Nombre; Surname = $n.Apellido
                SamAccountName = $n.Usuario; UserPrincipalName = "$($n.Usuario)@$($dominio.DNSRoot)"
                Path = $ou; Enabled = $false; PasswordNeverExpires = $true
            }
            New-ADUser @usuario
        }
        do {
            $clave = Read-Host -AsSecureString "Clave de $($n.Usuario)"
            try {
                Set-ADAccountPassword -Identity $n.Usuario -Reset -NewPassword $clave -ErrorAction Stop
                $ok = $true
            } catch {
                Write-Warning "No se pudo poner esa clave: $($_.Exception.Message)"
                Write-Warning 'Usa al menos 7 caracteres con mayúsculas, minúsculas y números.'
                $ok = $false
            }
        } until ($ok)
        Enable-ADAccount -Identity $n.Usuario
        Add-ADGroupMember -Identity $n.Grupo -Members $n.Usuario
    }
    foreach ($g in (Get-ADGroup -Filter "Name -like 'GRP-NIVEL-*'" -SearchBase $ou | Sort-Object Name)) {
        '{0,-13} {1}' -f $g.Name, ((Get-ADGroupMember $g).SamAccountName -join ', ')
    }
}

# --- Parte 4 · NPS: rol, registro en AD y clientes RADIUS R-0813 y SW-0813 ----
& {
    Install-WindowsFeature NPAS -IncludeManagementTools
    Import-Module NPS
    netsh nps add registeredserver
    do {
        $a = Read-Host -AsSecureString 'Secreto RADIUS (el mismo que pondrás en R-0813 y SW-0813)'
        $b = Read-Host -AsSecureString 'Repite el secreto'
        $s1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($a))
        $s2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($b))
        if (-not $s1 -or $s1 -ne $s2) { Write-Warning 'Está vacío o no coincide. Otra vez.' }
    } until ($s1 -and $s1 -eq $s2)
    foreach ($c in @(@{ Nombre = 'R-0813'; IP = '10.20.25.1' }, @{ Nombre = 'SW-0813'; IP = '10.20.25.2' })) {
        if (Get-NpsRadiusClient | Where-Object Name -eq $c.Nombre) { Remove-NpsRadiusClient -Name $c.Nombre }
        New-NpsRadiusClient -Name $c.Nombre -Address $c.IP -SharedSecret $s1 | Out-Null
    }
    Restart-Service IAS
    Get-NpsRadiusClient | Format-Table Name, Address, VendorName, Enabled
}

# --- Parte 5 · Directivas de red CISCO-NIVEL-10, -5 y -0 (orden 1, 2 y 3) -----
#  Condición: grupo de Windows · Acceso concedido · Solo PAP ·
#  Cisco-AV-Pair (atributo 26, proveedor 9, tipo 1) = shell:priv-lvl=N.
#  Sin Framed-Protocol ni Service-Type. Las de fábrica quedan debajo.
#  Nota: netsh guarda el atributo como un Vendor-Specific genérico (proveedor 9,
#  tipo 1). En la práctica se cambió en la consola NPS por el atributo con nombre:
#  directiva ▸ Properties ▸ Settings ▸ Vendor Specific ▸ Add ▸ Cisco-AV-Pair ▸
#  Add ▸ shell:priv-lvl=N (evidencia 06). Así llega al equipo como
#  Cisco AVpair "shell:priv-lvl=N" (evidencia 14).
& {
    $leer = {
        $lista = @(); $p = $null
        foreach ($l in (netsh nps show np)) {
            if ($l -match '^\s*Name\s+=\s+(.+?)\s*$') { $p = [pscustomobject]@{ Nombre = $Matches[1]; Orden = $null }; $lista += $p }
            elseif ($p -and $l -match '^\s*Processing order\s+=\s+(\d+)') { $p.Orden = [int]$Matches[1] }
        }
        $lista
    }
    $niveles = @(
        @{ Directiva = 'CISCO-NIVEL-10'; Grupo = 'GRP-NIVEL-10'; AvPair = 'shell:priv-lvl=10'; Orden = 1 },
        @{ Directiva = 'CISCO-NIVEL-5';  Grupo = 'GRP-NIVEL-5';  AvPair = 'shell:priv-lvl=5';  Orden = 2 },
        @{ Directiva = 'CISCO-NIVEL-0';  Grupo = 'GRP-NIVEL-0';  AvPair = 'shell:priv-lvl=0';  Orden = 3 }
    )
    $cmds = @()
    $existentes = @(& $leer)
    foreach ($e in $existentes) {
        if ($e.Nombre -like 'CISCO-NIVEL-*') { $cmds += 'nps delete np name = "{0}"' -f $e.Nombre }
    }
    foreach ($e in ($existentes | Where-Object { $_.Nombre -notlike 'CISCO-NIVEL-*' -and $null -ne $_.Orden -and $_.Orden -le 3 } | Sort-Object Orden -Descending)) {
        $cmds += 'nps set np name = "{0}" processingorder = "{1}"' -f $e.Nombre, ($e.Orden + 1000)
    }
    foreach ($n in $niveles) {
        $sid = (Get-ADGroup $n.Grupo).SID.Value
        $vsa = '01' + '00000009' + '01' + ('{0:X2}' -f ($n.AvPair.Length + 2)) + $n.AvPair
        $cmds += ('nps add np name = "{0}" state = "enable" processingorder = "{1}" policysource = "0" ' +
                  'conditionid = "0x1fb5" conditiondata = "{2}" ' +
                  'profileid = "0x100f" profiledata = "TRUE" profileid = "0x1009" profiledata = "0x1" ' +
                  'profileid = "0x1a" profiledata = "{3}"') -f $n.Directiva, $n.Orden, $sid, $vsa
    }
    $archivo = Join-Path $env:TEMP 'np0813.txt'
    Set-Content -Path $archivo -Value $cmds -Encoding ASCII
    netsh -f $archivo
    Remove-Item $archivo
    netsh nps show np | Select-String -Pattern 'CISCO|Connections|rder|0x1009|0x1a'
}

# --- Parte 6 · Registros: auditoría del NPS (6272/6273) y accounting a archivo -
& {
    auditpol /set /subcategory:"{0CCE9243-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
    netsh nps set filelog accounting = enable authentication = enable periodicstatus = enable frequency = monthly
    Restart-Service IAS
    auditpol /get /subcategory:"{0CCE9243-69AE-11D9-BED3-505054503030}"
    netsh nps show filelog
}

# --- Parte 7 · Después de las pruebas (Paso 28): eventos, accounting y export -
& {
    Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 6272, 6273 } -MaxEvents 10 |
        Format-Table TimeCreated, Id, @{ n = 'Usuario'; e = { $_.Properties[1].Value } } -AutoSize
    Get-ChildItem C:\Windows\System32\LogFiles\IN*.log | Sort-Object LastWriteTime | Select-Object -Last 1 | Get-Content -Tail 5
    netsh nps export filename="C:\nps-0813.xml" exportPSK=NO
}
