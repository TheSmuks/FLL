# Marcador Automático FLL — OBS

Configuración del marcador de la FIRST Lego League en OBS Studio.

## Estructura del proyecto

```
.
├── FLL_scenes.json          # Colección de escenas — importar esto primero
├── curtain.lua              # Script de recarga automática con cortina
├── timer.lua                # Script del temporizador de ronda
├── table.css                # CSS para aislar el marcador a pantalla completa
├── images/
│   ├── background.png       # Fondo de la cortina
│   └── loading_animation.gif # Animación de carga
├── audio/
│   ├── Timer-01.mp3
│   ├── Timer-02.mp3
│   └── Timer-03.mp3
└── FLL/
    └── basic.ini            # Perfil base de OBS para FLL
```

---

## Configuración rápida

1. Abre OBS → **Colección de escenas → Importar** → selecciona **`FLL_scenes.json`**.
2. Revisa que todo carga bien: escenas, fuentes, cortina y scripts.
3. Listo. Si algo no funciona, consulta la sección correspondiente abajo.

---

## Troubleshooting

### El marcador web no se ve a pantalla completa o se ven menús del sitio

El CSS personalizado no se ha aplicado o se ha perdido al importar.

1. Doble clic en la fuente **Browser**.
2. Comprueba que la url es la que toca.
3. En **CSS personalizado**, borra todo y pega el contenido de **`table.css`**.
4. Si no queda centrado: clic derecho sobre la fuente → **Transformar → Estirar a la pantalla** (`Ctrl+S`).

### La cortina de "Cargando" no aparece o no tapa el marcador

El grupo `Update_Curtain` no existe o le faltan elementos.

1. Comprueba que en la escena existen estas tres fuentes:
   - **Texto (GDI+)** con el texto "Cargando".
   - **Fuente multimedia** apuntando a `images/loading_animation.gif`.
   - **Imagen** apuntando a `images/background.png`.
2. Si no están agrupadas: selecciona las tres (`Ctrl+clic`), clic derecho → **Agrupar los elementos seleccionados** → nombrar `Update_Curtain`.
3. Clic derecho sobre el grupo → **Mostrar transición** → Desvanecimiento. Igual en **Ocultar transición**.

### El script de recarga automática no funciona

1. Ve a **Herramientas → Scripts**. Si `curtain.lua` no aparece, pulsa **+** y selecciónalo de la carpeta del proyecto.
2. En el panel derecho, comprueba que los nombres coinciden exactamente con tus fuentes en OBS:
   - **Scene Name:** nombre de tu escena (ej. `Website_Feed`)
   - **Browser Source:** nombre de tu fuente web (ej. `Browser`)
   - **Group Name:** `Update_Curtain`
   - **Text Source Name:** nombre de tu fuente de texto (ej. `Status Text`)
   - **Message:** `Cargando`
   - **Interval (Minutes):** `5`
   - **Wait Time (Seconds):** `15`

Controles durante el evento:
- **▶ START AUTOMATION** — Arranca el temporizador de 5 min.
- **🔄 REFRESH NOW** — Fuerza una recarga inmediata.
- **⏹ STOP** — Detiene la automatización.

### El audio no sale por HDMI (altavoces de la pista)

1. Ve a **Archivo → Ajustes → Audio → Monitorización de audio** y selecciona el dispositivo HDMI.
2. En el **Mezclador de audio**, clic en el engranaje (⚙) de la fuente de audio → **Propiedades avanzadas de audio**.
3. En **Monitorización de audio**, cambia a:
   - **Solo monitorización** — sale solo por HDMI, no se graba.
   - **Monitorización y salida** — sale por HDMI y se graba.
4. Para los temporizadores (`audio/Timer-01.mp3`, etc.), usa **Monitorización y salida** si quieres que suenen en pista y queden grabados.

Activa **Studio Mode** (botón esquina inferior derecha) para preparar cambios de escena sin que se vean en la salida de programa.

### NDI no funciona o no se detectan fuentes

Necesitas [DistroAV](https://github.com/DistroAV/DistroAV) (antes OBS-NDI). Requiere OBS 31+ y NDI Runtime 6+.

**Instalación:**
- **Windows:** `winget install --exact --id DistroAV.DistroAV`
- **macOS:** `brew install --cask distroav`
- **Linux (Flatpak):**
  ```
  flatpak install com.obsproject.Studio.Plugin.DistroAV
  sudo flatpak override com.obsproject.Studio --system-talk-name=org.freedesktop.Avahi
  ```

Si no tienes el NDI Runtime, descárgalo desde la [wiki de DistroAV](https://github.com/DistroAV/DistroAV/wiki/1.-Installation#required---ndi-runtime). En Windows, reinicia después de instalarlo.

**Emitir una fuente por NDI:**
1. Clic derecho sobre la escena o fuente → **Filtros**.
2. En **Filtros de efectos**, pulsa **+** → **Dedicated NDI Output**.
3. Ponle nombre (ej. `Marcador FLL`). Ya está disponible en la red.