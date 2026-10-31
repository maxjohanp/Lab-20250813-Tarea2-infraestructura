# Evidencias

Capturas tomadas durante la práctica (30 de octubre de 2026). Las claves y la línea `key 7` del RADIUS están tapadas.

| # | Archivo | Qué se ve |
|---|---|---|
| 01 | [`01-topologia-gns3.png`](01-topologia-gns3.png) | Proyecto de GNS3: R1 (R-0813) f0/0 ↔ e0 Switch-2 (SW-0813) e1 ↔ e0 SRV-AD0813-1 |
| 02 | [`02-srv-red-y-dominio.png`](02-srv-red-y-dominio.png) | Server Manager ▸ Local Server: SRV-AD0813, dominio `lab0813.local`, Ethernet 10.20.25.10, zona horaria UTC-4, VirtualBox |
| 03 | [`03-ad-grupos-y-usuarios.png`](03-ad-grupos-y-usuarios.png) | Active Directory Users and Computers ▸ OU AAA-Redes: GRP-NIVEL-0, 5 y 10 y sus tres usuarios |
| 04 | [`04-nps-clientes-radius.png`](04-nps-clientes-radius.png) | NPS ▸ RADIUS Clients: R-0813 (10.20.25.1) y SW-0813 (10.20.25.2) |
| 05 | [`05-nps-directivas.png`](05-nps-directivas.png) | NPS ▸ Network Policies: CISCO-NIVEL-10, 5 y 0 en orden 1, 2 y 3; las de fábrica en 999998 y 999999 |
| 06 | [`06-nps-atributo-priv-lvl.png`](06-nps-atributo-priv-lvl.png) | CISCO-NIVEL-0 ▸ Settings ▸ Vendor Specific: Cisco-AV-Pair = `shell:priv-lvl=0`, PAP, grupo `LAB0813\GRP-NIVEL-0` |
| 07 | [`07-nps-accounting.png`](07-nps-accounting.png) | NPS ▸ Accounting ▸ Log File Properties: `C:\Windows\system32\LogFiles`, DTS Compliant, mensual |
| 08 | [`08-r-aaa-config.png`](08-r-aaa-config.png) | R-0813 en nivel 15: `show running-config \| section aaa` y `section line` |
| 09 | [`09-sw-aaa-config.png`](09-sw-aaa-config.png) | SW-0813: depuración AAA/RADIUS activada y `show running-config \| section aaa` |
| 10 | [`10-sw-line-config.png`](10-sw-line-config.png) | SW-0813: `enable` registrado por el archivo de cambios y `show running-config \| section line` |
| 11 | [`11-sw-vlan-y-gestion.png`](11-sw-vlan-y-gestion.png) | SW-0813: interfaz Vlan13 10.20.25.2, puertos sin uso apagados, `show vlan brief` |
| 12 | [`12-sw-ssh-y-aaa.png`](12-sw-ssh-y-aaa.png) | SW-0813: llaves RSA de 2048 bits, SSH v2, ACL-SSH, `aaa new-model` y `line vty` |
| 13 | [`13-sw-ssh-v2-y-guardado.png`](13-sw-ssh-v2-y-guardado.png) | SW-0813: `show ip ssh` (versión 2.0, aes-ctr) y `copy running-config startup-config` |
| 14 | [`14-r-test-aaa-radius.png`](14-r-test-aaa-radius.png) | R-0813: ping al NPS, `test aaa` con soporte0813 aceptado con priv-lvl 5 y depuración RADIUS (Access-Accept) |
| 15 | [`15-sw-test-aaa-radius.png`](15-sw-test-aaa-radius.png) | SW-0813: `radius server NPS-0813`, `show aaa servers` y `test aaa` aceptado con priv-lvl 5 |
| 16 | [`16-r-consola-ad-nivel10.png`](16-r-consola-ad-nivel10.png) | Consola de R-0813: cierre por inactividad y entrada de operador0813 (AD) en nivel 10 |
| 17 | [`17-sw-consola-ad-nivel10.png`](17-sw-consola-ad-nivel10.png) | Consola de SW-0813: entrada de operador0813 (AD) en nivel 10 |
| 18 | [`18-r-ssh-login-block-for.png`](18-r-ssh-login-block-for.png) | SSH desde 10.20.25.10 con aes128-cbc: 3 claves malas, Quiet-Mode de 120 s y la consola sigue entrando por RADIUS |
| 19 | [`19-nps-evento-6273.png`](19-nps-evento-6273.png) | Evento 6273 del NPS con el motivo 16 (credenciales que no coinciden) |
| 20 | [`20-ssh-cifrados-cbc.png`](20-ssh-cifrados-cbc.png) | Cliente SSH de Windows sin cifrado en común con el 7200 (solo ofrece CBC) |
| 21 | [`21-sw-radius-sintaxis-antigua.png`](21-sw-radius-sintaxis-antigua.png) | IOSvL2 rechaza `radius-server host … key …` (sintaxis antigua) |
