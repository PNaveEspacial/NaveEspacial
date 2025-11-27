# shooter-pygame
Juego de shooter en pygame 


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
