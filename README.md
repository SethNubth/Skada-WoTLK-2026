# KadeSkada - Sempiternal Edition 🔥
### Naerzone 3.3.5a - Anti-Bug Pack Sindragosa 25H P3

> **Original by bkader is for noobs. This one flames your raid for you.**

**Base:** [Skada-WoTLK by bkader](https://github.com/bkader/Skada-WoTLK) - Heavy modified  
**Author:** **SethNubth (Kade)** - <Sempiternal> - Naerzone - ICC 25H  
**Interface:** 30300 (3.3.5a 12340)

---

### 💀 ¿Qué tiene que bkader NO tiene?

| Feature | bkader Skada | Naerzone|
| :--- | :--- | :--- |
| **Sindragosa P3 Magia Tracking** | ❌ No | ✅ `Magia 8 Dañó 13483700 Mató 2 7:15,35s` |
| **No flamea al romper tumbas** | ❌ Te dice flamer por romper | ✅ Fix Ice Tomb 70157 |
| **Threat avisa en banda** | ❌ Solo local | ✅ `Amenaza De: %s 98% Bajar el agro Porfavor...` cada 20s en /RW |
| **Parry no cuenta en tumba** | ❌ Infla parrys en P3 | ✅ Fix haste fake |
| **Inspect 3D en combate** | ❌ No | ✅ Snapshot pull + modelo giratorio |
| **Timer GOD 5:36,34s** | ❌ 5:36 | ✅ `7:15,35s` con ms |

---

### 🔥 PACK P3 - Módulos

#### 1. `SindraFF.lua` - NEW - GOD TIER
Sindragosa 25H P3 - Magia DesencadenadaArquímedes Magia 8 Dañó 13483700 Mató : Juan, Pepito 7:15,35s
Seteado Magia 6 Dañó 5400000 Mató 0 7:22,10s
P3 Limpia - Sin fuego amigo

- Click1: Detalle por PJ - ¿A quién dañó?
- Click2: Muertos por Magia - ¿A quién MATÓ y con cuántas cargas?
- Auto-detect 35% por `boss1 UNIT_HEALTH`

#### 2. `Threat.lua` - FIXED - RAID FLAME
```lua
-- Si pasas 95% te flamea en banda solo, cada 20s
-- No avisa si estás en Tumba Helada (amenaza congelada)
SendChatMessage("Amenaza De: Juan 98% Bajar el agro Porfavor.......", "RAID_WARNING")

3. Parry.lua - FIXEDNo cuenta parry si estás en tumba (era fake haste)Sindragosa parreó a Juan (3) - 5:36,34s [Parry 6]4. FriendlyFire.lua - FIXED - ANTI FLAMEAntes: Rompías tumba y te decía "30k Friendly Fire a Pepito"Ahora: Ignora 70157/70213/71056 - No es FF, es mecánica5. Avoidance.lua - FIXEDNo infla Dodge/Parry si estás tumbado6. Inspect.lua - NEW - FLEX/inspect3d - Ves el mono 3D del targetAuto-guarda ilvl + Trinkets BIS 284 + Shadowmourne al pullPa' ver quien viene con Organ 264 en 25H
📦 Instalación
Borra Interface/AddOns/SkadaClona este repo en Interface/AddOns/SkadaVerifica Modules/Load.xml tenga al final:
/reload/skada config -> Activa los 3 nuevos

###🧪 Test Commands (Sin estar en ICC)/sindra - Fuerza P3 y testea el tracker/inspect3d - Abre el visor 3D/threat test - Testea el aviso

🏆 Créditosbkader - Hizo el Skada base (respeto, pero nos tocó fixearlo)SethNubth (Kade) - Todo el Pack P3, Threat Raid, Inspect 3D, SindraFFSempiternal - Guild que wipeó 100 veces en Sindra pa' testear estoNaerzone - Donde el FriendlyFire por tumba no debería contar nunca

⚠️ Anti-Bug NaerzoneEste Skada corrige bugs específicos de TrinityCore 3.3.5a:C_Timer.After no existe -> ScheduleTimerENCOUNTER_START no dispara -> UNIT_HEALTH boss1 35%Ice Tomb damage contado como FF, Parry, Threat -> Todo filtrado con 70157bkader, if you read this: your Skada was good, but KadeSkada is GOD. Pull request? Nah, we already fixed it.License: Same as original Skada (GPL) - Pero con esteroides de Naerzone.

