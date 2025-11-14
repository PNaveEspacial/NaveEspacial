# ============================================================================
# nucleo/constantes.py
# Este archivo contiene TODAS las constantes del juego.
# Son valores que no cambian mientras se ejecuta el programa.
# Aquí definimos tamaños, dimensiones y parámetros base
# que usan los demás módulos del núcleo y de la cáscara.
# ============================================================================

# --- Tamaño general de la ventana del juego ---
ANCHO = 800   # Ancho de la pantalla en píxeles
ALTO  = 600   # Alto de la pantalla en píxeles

# --- Tamaños de los diferentes objetos del juego ---
PLAYER_W, PLAYER_H   = 60, 60   # Tamaño de la nave del jugador
ENEMY_W, ENEMY_H     = 60, 60   # Tamaño de los enemigos comunes
BULLET_W, BULLET_H   = 10, 25   # Tamaño de las balas del jugador
EBULLET_W, EBULLET_H = 12, 25   # Tamaño de las balas enemigas

# --- Tamaño y vida del jefe final ---
BOSS_W, BOSS_H = 160, 120   # Tamaño del jefe
BOSS_HP        = 600        # Vida total del jefe (puntos de resistencia)

# --- Control de tiempos y pausas entre oleadas ---
PREBOSS_PAUSE_TICKS = 180   # Pequeña pausa antes de que aparezca el jefe
ENEMY_WAVE_COOLDOWN = 90    # Tiempo entre una oleada de enemigos y la siguiente
MIXED_WAVE_COOLDOWN = 90    # Pausa para oleadas mixtas (enemigos + meteoritos)

# ============================================================================
# Nota:
# - Estos valores ayudan a mantener orden y equilibrio en el juego.
# - Si se necesita ajustar la dificultad, se puede cambiar aquí la vida del jefe,
#   la pausa entre oleadas o el tamaño de los objetos sin modificar el resto del código.
# ============================================================================