# SRV-AD0813 · configuración aplicada (Active Directory y NPS)

Windows no tiene un *running-config* de texto como IOS. Este archivo recoge la configuración aplicada en el servidor, sin secretos, y las capturas que la muestran (carpeta [`docs/Evidencias`](../docs/Evidencias)). Se hizo con [`scripts/SRV-AD0813_config.ps1`](../scripts/SRV-AD0813_config.ps1).

## Equipo · captura 02

| Parámetro | Valor |
|---|---|
| Sistema | Windows Server 2022 Standard Evaluation (Desktop Experience) |
| Virtualización | Máquina virtual de VirtualBox (4 GB de RAM) añadida a GNS3 como nodo VirtualBox (`SRV-AD0813-1`) |
| Nombre | SRV-AD0813 |
| Adaptador | `Ethernet` (adaptador 1 de VirtualBox = puerto e0 del nodo en GNS3, cableado a e1 = Gi0/1 del switch) |
| IP · máscara · gateway | 10.20.25.10 · 255.255.255.0 · 10.20.25.1 |
| DNS | 10.20.25.10 (el propio controlador de dominio) |
| Zona horaria | (UTC-04:00) Georgetown, La Paz, Manaus, San Juan |
| Firewall | Regla *File and Printer Sharing (Echo Request - ICMPv4-In)* habilitada para el ping |

## Active Directory · captura 03

| Parámetro | Valor |
|---|---|
| Bosque y dominio | `lab0813.local` · NetBIOS `LAB0813` · nivel funcional Windows Server 2016 |
| Roles | AD DS y DNS (zona `lab0813.local`) |
| Unidad organizativa | `OU=AAA-Redes,DC=lab0813,DC=local` |

| Grupo (global, seguridad) | Descripción | Usuario miembro | Nivel en Cisco |
|---|---|---|---|
| GRP-NIVEL-0 | Cisco privilege level 0 | `invitado0813` (Invitado Nivel 0) | 0 |
| GRP-NIVEL-5 | Cisco privilege level 5 | `soporte0813` (Soporte Nivel 5) | 5 |
| GRP-NIVEL-10 | Cisco privilege level 10 | `operador0813` (Operador Nivel 10) | 10 |

Usuarios habilitados, con contraseña que no caduca y la opción de marcado por defecto (*Control access through NPS Network Policy*). Contraseñas: `<ELIMINADO>`.

## NPS · capturas 04 a 07

Rol *Network Policy and Access Services*, registrado en Active Directory (`netsh nps add registeredserver`).

### Clientes RADIUS · captura 04

| Nombre | Dirección | Proveedor | Estado | Secreto compartido |
|---|---|---|---|---|
| R-0813 | 10.20.25.1 | RADIUS Standard | Enabled | `<ELIMINADO>` |
| SW-0813 | 10.20.25.2 | RADIUS Standard | Enabled | `<ELIMINADO>` |

### Directivas · capturas 05 y 06

Directiva de solicitud de conexión: la de fábrica, *Use Windows authentication for all users* (autentica en este mismo servidor).

| Orden | Directiva de red | Condición | Permiso | Autenticación | Atributo enviado |
|---|---|---|---|---|---|
| 1 | CISCO-NIVEL-10 | User Groups = `LAB0813\GRP-NIVEL-10` | Grant Access | PAP | Cisco-AV-Pair = `shell:priv-lvl=10` |
| 2 | CISCO-NIVEL-5 | User Groups = `LAB0813\GRP-NIVEL-5` | Grant Access | PAP | Cisco-AV-Pair = `shell:priv-lvl=5` |
| 3 | CISCO-NIVEL-0 | User Groups = `LAB0813\GRP-NIVEL-0` | Grant Access | PAP | Cisco-AV-Pair = `shell:priv-lvl=0` |
| 999998 | Connections to Microsoft Routing and Remote Access server | (de fábrica) | Deny Access | — | — |
| 999999 | Connections to other access servers | (de fábrica) | Deny Access | — | — |

- Autenticación: *Unencrypted authentication (PAP, SPAP)*, que es lo que envían IOS y `test aaa`. La clave viaja protegida con el secreto compartido.
- Atributos: sin *Framed-Protocol* ni *Service-Type*. El Cisco-AV-Pair (atributo 26, proveedor 9) llega al equipo como `Cisco AVpair "shell:priv-lvl=N"` (captura 14).
- Un usuario que no está en ninguno de los tres grupos cae en las directivas de fábrica y recibe Access-Reject.

## Registros · capturas 07 y 19

| Registro | Configuración | Dónde se ve |
|---|---|---|
| Auditoría | `auditpol` ▸ subcategoría *Network Policy Server*: Success and Failure | Visor de eventos ▸ Security: 6272 (acceso concedido) y 6273 (acceso denegado, con el motivo) |
| Accounting | Archivo de texto `INyymm.log` en `C:\Windows\system32\LogFiles`, formato DTS Compliant, un archivo nuevo por mes y borrado de los más viejos si el disco se llena | Solicitudes de autenticación y registros Start / Stop de las sesiones |

## Cómo comprobarlo en el servidor

```powershell
Get-NpsRadiusClient | Format-Table Name, Address, Enabled
netsh nps show np
netsh nps show filelog
auditpol /get /subcategory:"{0CCE9243-69AE-11D9-BED3-505054503030}"
Get-ADGroupMember GRP-NIVEL-5 | Select-Object SamAccountName
Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 6272, 6273 } -MaxEvents 10
```
