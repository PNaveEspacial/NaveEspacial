from dataclasses import replace
from typing import Tuple
from .constantes import ANCHO, PLAYER_W
from .geom import _clamp
from .estados import EstadoJugador, EstadoBala

# ============================================================================
# jugador.py — Lógica funcional del jugador (sin efectos colaterales)
# Este módulo controla: daño, movimiento y disparos.
# Usa dataclasses inmutables y funciones puras.
# ============================================================================

def _daño(j: EstadoJugador, cantidad: int = 1, invul: int = 300) -> EstadoJugador:
    """
    Aplica daño al jugador de manera pura:
      - Solo si NO está invulnerable.
      - Al recibir daño, activa invulnerabilidad (invul_frames) por cierto tiempo.
      - Por defecto, 300 frames ≈ 5 segundos (a 60 FPS).
    """
    if j.invul_frames > 0:
        # Si todavía está en modo invulnerable, no recibe daño.
        return j
    nuevo = max(0, j.corazones - cantidad)
    # Se devuelve un NUEVO jugador con corazones reducidos e invul_frames activos.
    return replace(j, corazones=nuevo, vivo=(nuevo > 0), invul_frames=invul)

def _tick_invul(j: EstadoJugador) -> EstadoJugador:
    """
    Disminuye el contador de invulnerabilidad en 1 por cada frame.
    Cuando llega a 0, el jugador vuelve a ser vulnerable.
    """
    return replace(j, invul_frames=max(0, j.invul_frames - 1)) if j.invul_frames > 0 else j

def mover_jugador(jugador: EstadoJugador, direccion: int) -> EstadoJugador:
    """
    Mueve la nave del jugador horizontalmente (izquierda/derecha):
      - dirección = -1 → izquierda
      - dirección =  1 → derecha
    Usa _clamp() para no salir del borde de la pantalla.
    """
    nuevo_x = _clamp(jugador.x + direccion * 5, 0, ANCHO - PLAYER_W)
    return replace(jugador, x=nuevo_x)

def disparar_bala(jugador: EstadoJugador, balas: Tuple[EstadoBala, ...]) -> Tuple[EstadoBala, ...]:
    """
    Crea una nueva bala justo en el centro superior de la nave.
    Devuelve una nueva tupla con la bala agregada (sin modificar la anterior).
    """
    from .constantes import BULLET_W
    bx = jugador.x + (PLAYER_W // 2 - BULLET_W // 2)
    return balas + (EstadoBala(x=bx, y=jugador.y),)

def actualizar_balas(balas: Tuple[EstadoBala, ...]) -> Tuple[EstadoBala, ...]:
    """
    Actualiza la posición de todas las balas activas:
      - Usa funciones de orden superior (filter + map).
      - Elimina las que salieron de pantalla (y < -40).
      - Devuelve una nueva tupla con las posiciones actualizadas.
    """
    visibles = filter(lambda b: b.y + b.velocidad_y > -40, balas)
    nuevas = map(lambda b: replace(b, y=b.y + b.velocidad_y), visibles)
    return tuple(nuevas)
