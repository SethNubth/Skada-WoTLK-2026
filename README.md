# Skada-WoTLK-2026
Skada WoTLK - 3.3.5 Modifi Bkader 
# KadeSkada - Naerzone Fix 🔥

> **The only Skada that doesn't break on Sindragosa P3**

Fix personalizado para Naerzone / Warmane WotLK 3.3.5a que soluciona el bug más flameado de ICC: **Las Tumbas Heladas en Sindragosa rompen el DPS.**

### 🐛 El Bug Original (Skada Retail)
Cuando Sindragosa lanza Tombas Heladas en P3, Skada considera a los jugadores con tumba como "muertos" o fuera de combate. Resultado: DPS congelado, HPS roto, y todo tu parse a la mierda.

### ✅ El Fix KadeSkada
Reescribí la detección de combate para Sindragosa:
- `UNIT_AURA` / `Ice Tomb` ya no corta el segmento de daño
- Fix en `Skada\Modules\Damage\` - El daño sigue contando dentro de la tumba
- Compatible con 100% de los demás bosses de ICC/RS

### 📦 Instalación
1. Borra tu Skada viejo en `Interface\AddOns\`
2. Descarga este repo: Code > Download ZIP
3. Renombra a `Skada` y ponlo en `Interface\AddOns\`
4. `/reload` y a reventar DPS en Sindra

### 🔧 Versión
Based on Skada 1.7.9 - WotLK Classic
Fix Version: 2.0 - Kade Edition for Naerzone

### 👑 Credits
- Original Author: Zarnivoop
- WotLK Port: Original Devs
- **Naerzone Fix & P3 Rework: Kade / SethNubth**
- Testeado en: Naerzone - Ciudadela Corona de Hielo 25H

> "Si tu Skada se rompe en Sindra, no es tu DPS, es tu addon." - Kade

---

**[ Download Latest Release ]**
