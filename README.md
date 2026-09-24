# shooter-pygame
Juego de shooter nave espacial aplicando conceptos de programacion funcional


```
NaveEspacial-Funcional/
├── assets/                                  # Imágenes, sprites, sonidos
│
├── cascara_imperativa/                      # Capa Imperativa (Pygame)
│   ├── __init__.py
│   ├── arranque.py                          # Punto de entrada del juego
│   ├── assets.py                            # Carga de imágenes y recursos
│   ├── audio.py                             # Reproducción de música y efectos
│   ├── bucle.py                             # Game loop principal
│   ├── estilos_ui.py                        # Botones, textos, UI
│   ├── pantallas.py                         # Menús, pausa, instrucciones, game over
│   ├── records.py                           # Lectura/escritura de puntajes
│   ├── records.txt                          # Puntajes guardados
│   ├── renderizado.py                       # Dibujo de sprites, HUD y animaciones
│   └── __pycache__/                         # Caché interno de Python
│
├── nucleo/                                  # Núcleo funcional (lógica pura)
│   ├── __init__.py
│   ├── colisiones.py                        # Detección de colisiones puras
│   ├── constantes.py                        # Constantes globales del juego
│   ├── enemigos.py                          # Movimiento y disparos de enemigos
│   ├── enums_eventos.py                     # Enumeraciones internas del juego
│   ├── estados.py                           # Estados inmutables del jugador y enemigos
│   ├── flujo.py                             # Control de modos del juego
│   ├── geom.py                              # Utilidades geométricas (rectángulos, clamp)
│   ├── jefe.py                              # Lógica funcional del jefe
│   ├── jugador.py                           # Movimiento, disparo y daño del jugador
│   ├── meteoritos.py                        # Movimiento y reposición de meteoros
│   ├── rng.py                               # Random funcional con semillas
│   └── __pycache__/                         # Caché interno de Python
│
├── test_nucleo_core.py                      # Pruebas unitarias del núcleo funcional
├── requirements.txt                         # Dependencias del proyecto
└── README.md                                # Documentación del repositorio




Arquitectura: Functional Core / Imperative Shell

┌────────────────────────────────────────────────────────────┐
│  CÁSCARA IMPERATIVA (Pygame)                               │
│  - Menús, pausa, game over                                 │
│  - Dibujado de sprites                                     │
│  - Reproducción de sonidos                                 │
│  - Lectura del teclado                                     │
│  - Manejo de recursos                                      │
│                                                            │
│          ↓ Envía acciones del jugador                      │
│                                                            │
│      ┌───────────────────────────────────────┐             │
│      │       NÚCLEO FUNCIONAL (puro)         │             │
│      │  - Estados inmutables                 │             │
│      │  - Movimiento del jugador             │             │
│      │  - Meteoritos y enemigos              │             │
│      │  - IA y dificultad                    │             │
│      │  - Colisiones                         │             │
│      │  - Lógica del jefe                    │             │
│      └───────────────────────────────────────┘             │
│                                                            │
│          ↑ Devuelve un nuevo estado limpio                 │
└────────────────────────────────────────────────────────────┘


Flujo de ejecución del juego

USUARIO
   │ Presiona teclas
   ▼
CÁSCARA IMPERATIVA (Pygame)
   │ Captura eventos
   │ Envía acción (mover, disparar)
   ▼
NÚCLEO FUNCIONAL
   │ Actualiza estado puro del juego
   │ (posiciones, colisiones, puntaje)
   ▼
CÁSCARA IMPERATIVA
   │ Dibuja nave, enemigos, meteoritos
   │ Reproduce sonidos
   │ Actualiza HUD
   ▼
PANTALLA
```

## Godot rebuild (current project)

`game/` is the current, actively developed project: a pixel-art, infinite
wave-based roguelite rebuild of this shooter, in Godot 4.7.2. `nucleo/`,
`cascara_imperativa/`, `assets/`, and `test_nucleo_core.py` are the legacy
Pygame reference implementation. They stay in place and stay runnable; they
are not modified by the Godot rebuild.

### GUT test tooling

The GUT (Godot Unit Test) addon is installed by a pinned, checksum-verified
script rather than committed to the repository, so it never needs to be
tracked or updated manually.

Install (from the `game/` directory):

```powershell
tools\install_gut.ps1
```

```bash
tools/install_gut.sh
```

Both scripts download the pinned GUT release, verify its SHA-256 against the
value pinned in the script, and fail closed (no partial install, non-zero
exit) on a checksum mismatch. Pass `-Force` (PowerShell) or `--force` (bash)
to reinstall.

Run the full headless test suite:

```powershell
tools\run_tests.ps1
```

```bash
tools/run_tests.sh
```

Both scripts resolve the Godot binary from the `GODOT_BIN` environment
variable, falling back to the pinned default install path. Any extra
argument is forwarded to the GUT CLI, so a focused run looks like:

```powershell
tools\run_tests.ps1 -gdir=res://tests/unit/core
```
