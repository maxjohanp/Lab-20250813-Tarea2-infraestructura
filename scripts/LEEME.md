# Scripts

| Orden | Archivo | Equipo | Qué hace | Cómo se usa |
|---|---|---|---|---|
| 1 | [`SRV-AD0813_config.ps1`](SRV-AD0813_config.ps1) | SRV-AD0813 | Parte 1 red y nombre · 2 bosque `lab0813.local` · 3 OU, grupos de nivel 0, 5 y 10 y usuarios · 4 NPS y clientes RADIUS · 5 directivas de red · 6 auditoría y *accounting* · 7 consulta de eventos y registros | Cada parte `& { … }` se copia y se pega en Windows PowerShell como administrador. Las claves y el secreto se escriben cuando la parte los pide |
| 2 | [`R-0813_config.txt`](R-0813_config.txt) | R-0813 | Bloques 1 a 8: base y endurecimiento, usuario local y claves por nivel, comandos de cada nivel, SSH v2, cliente RADIUS, AAA en consola y AUX, registros, comprobación | Se pega bloque por bloque en la consola de GNS3, cambiando cada `<CLAVE-…>` |
| 3 | [`SW-0813_config.txt`](SW-0813_config.txt) | SW-0813 | Lo mismo que el router, más VLAN 13 de gestión y puertos sin uso en VLAN 999. Usa la sintaxis `radius server` que pide IOSvL2 | Igual que el anterior |
| 4 | [`limpiar-secretos.ps1`](limpiar-secretos.ps1) | PC con Windows | Cambia claves, hashes y el secreto RADIUS de los running-config por `<ELIMINADO>` | `powershell -ExecutionPolicy Bypass -File scripts\limpiar-secretos.ps1 configs\*_running-config.txt` |

Notas de la práctica:

- La parte 5 crea las tres directivas con `netsh`. El atributo `shell:priv-lvl` se dejó como **Cisco-AV-Pair** desde la consola de NPS (directiva ▸ *Settings* ▸ *Vendor Specific*), como se ve en la evidencia 06.
- Router: el 7200 de GNS3 trae `privilege level 15` en `line con 0` y `line aux 0`; el bloque 6 lo quita. Para entrar por SSH desde Windows se usa `ssh -c aes128-cbc admin0813@10.20.25.1` (el IOS del 7200 solo ofrece cifrados CBC).
- Las claves se escriben al configurar y no se guardan en ningún archivo del repositorio.
