# Skada - Sempiternal / Naerzone Pack - Changelog
**Author:** SethNubth - Sempiternal - Naerzone  
**Base:** Skada-WoTLK by bkader (https://github.com/bkader/Skada-WoTLK)  
**Interface:** 30300 (3.3.5a 12340)

---

## [v3.3.5-Seth-P3-FIX] - 2026-05-13
### Pack Anti-Bug Sindragosa 25H - Ultima Face (35%)

#### 🚀 NUEVO - `SindraFF.lua` - Magia Desencadenada 25H
- **Feature GOD:** Tracking de `Magia Desencadenada (69762/69766)` en P3 Sindragosa 25H
- Formato igual a Parry: `>>Arquímedes Magia 8 Dañó 13483700 Mató 2 7:15,35s`
- Detecta automáticamente 35% (P3) por `UNIT_HEALTH` boss1
- Click1: Detalle por PJ - A quién dañó y cuánto
- Click2: Muertos por Magia - Quién mató a quién y con cuántas cargas
- Comando: `/sindra` para forzar P3 (test)
- Anti-crash: Fix `GetTimeStr()` que daba `35,00s` -> ahora `,35s` correcto

#### 🚀 NUEVO - `Inspect.lua` - Inspect 3D
- Snapshot automático de gear al pull (`PLAYER_REGEN_DISABLED`)
- Modelo 3D DressUp giratorio (Right Click drag)
- Detecta BIS Trinkets ICC 284/277 y Legendarias (Shadowmourne, Val'anyr)
- Muestra ilvl promedio + trinkets + fecha snapshot
- Comandos: `/inspect3d` / `/insp3d`
- Fix 3.3.5a: Reemplazado `C_Timer.After` por `Skada:ScheduleTimer`

#### 🐛 FIX - `Threat.lua` - Aviso a Banda >95%
- **Feature:** Avisa en banda `/RAID` o `/RW` si alguien >95% threat (no tanke) cada 20s
- Mensaje: `Amenaza De: %s %d%% Bajar el agro Porfavor.......`
- **Fix P3 Sindragosa:** Ignora jugadores con debuff `Tumba Helada (70157/71057)` - Amenaza congelada no cuenta
- `IsTombed()` check en `add_to_threattable` y `Seth_RaidAnnounce`
- Config: `enableRaidWarn`, `raidThreshold (85-99%)`, `raidFrequency (10-60s)`, `raidChannel`

#### 🐛 FIX - `Parry.lua` - Parry-Haste
- Formato tiempo `5:36,34s` preciso (ms con `% 1 * 100`)
- **Fix P3:** Ignora parrys si el atacante tiene `Ice Tomb` (70157/71057/70126) - No hay haste real en tumba
- `ICE_TOMB_IGNORE` tabla añadida en `spell_missed` y `boss_damage_after_parry`
- Opciones: `Solo Dragones`, `Opcion 1: Juan 6 Parry total: X`, `Opcion 2: #1•Juan 1 = 5300 5:36,34s`

#### 🐛 FIX - `FriendlyFire.lua` - No flamear tumbas
- **CRÍTICO Naerzone:** Romper Tumba Helada hacía daño al tumbado y lo contaba como FF
- Fix: `ICE_TOMB_IGNORE = {70157, 71057, 70213, 71056, 57829, 70219}` - Ignora daño de explosión de tumba
- Check por nombre: `Ice Tomb`, `Tumba Helada`, `Frost Bomb`
- Detalle con tiempo `5:36,34s` y threshold configurable (default 5k)

#### 🐛 FIX - `Avoidance.lua` - No inflar avoidance en tumba
- Fix: No contar dodge/parry/miss si el player está en `Ice Tomb` - Datos falsos
- `if spellId == 70157 return end` - Previene inflado de stats en P3

---

## [v3.3.5-Seth-Base] - 2026-05-10
- Base Skada-WoTLK bkader
- Tweaks iniciales Naerzone

---
Comandos Test/sindra - Forzar P3 Sindragosa/inspect3d - Abrir visor 3D/threat - Test warnings/skada config - Ver módulosCréditosbkader - Skada originalSethNubth (Kade) - Pack Anti-Bug P3, Threat Raid Warn, Inspect 3D, SindraFFSempiternal - Naerzone - Testing 25H ICC
Comandos Test/sindra - Forzar P3 Sindragosa/inspect3d - Abrir visor 3D/threat - Test warnings/skada config - Ver módulosCréditosbkader - Skada originalSethNubth (Kade) - Pack Anti-Bug P3, Threat Raid Warn, Inspect 3D, SindraFFSempiternal - Naerzone - Testing 25H ICC
### Load.xml
```xml
<Script file="Avoidance.lua" />
<Script file="Inspect.lua" />
<Script file="SindraFF.lua" />
