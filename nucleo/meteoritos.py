from dataclasses import replace
from typing import Tuple
from .constantes import ANCHO, ALTO
from .estados import EstadoMeteoro
from .rng import azar_en_rango

# ============================================================================
# meteoros.py — Actualización funcional de meteoritos
# Idea clave: todo es inmutable. No “movemos” objetos, devolvemos NUEVOS.
# ============================================================================

def actualizar_meteoros(meteoros: Tuple[EstadoMeteoro, ...], semilla_azar: int, bonus_vel: int = 0):
    """
    Recorre todos los meteoritos y calcula su siguiente posición de forma pura.
    - Si un meteoro sale de la pantalla (abajo o por los lados), se “recicla”:
      reaparece arriba con nuevas coordenadas y velocidades aleatorias.
    - Si sigue en pantalla, simplemente se crea un NUEVO EstadoMeteoro con (x,y) avanzados.
    - Se retorna:
        (tupla_meteoros_actualizados, nueva_semilla)
    """
    nuevos = []
    s = semilla_azar

    for m in meteoros:
        # Avance básico: suma la velocidad actual, con un bonus opcional en Y.
        nx, ny = m.x + m.velocidad_x, m.y + (m.velocidad_y + bonus_vel)

        # Si se fue de pantalla (por abajo o a los costados), lo re-posicionamos arriba.
        if ny > ALTO + 10 or nx < -40 or nx > ANCHO + 40:
            # Nuevas posiciones/velocidades determinísticas a partir de la semilla
            s, rx = azar_en_rango(s, 0, ANCHO - m.ancho)     # x aleatoria dentro del ancho
            s, ry = azar_en_rango(s, -140, -100)             # y aleatoria por encima de la pantalla
            s, sx = azar_en_rango(s, -3, 3)                  # velocidad horizontal leve
            s, sy = azar_en_rango(s, 1 + bonus_vel, 4 + bonus_vel)  # caída vertical con bonus
            nuevos.append(EstadoMeteoro(rx, ry, sx, sy))
        else:
            # Sigue en pantalla → devolvemos el mismo meteoro pero con (x,y) nuevos
            nuevos.append(EstadoMeteoro(nx, ny, m.velocidad_x, m.velocidad_y))

    # Convertimos la lista a tupla para mantener inmutabilidad en el estado del juego.
    return tuple(nuevos), s


def reponer_meteoros(estado):
    """
    Garantiza que siempre haya 8 meteoritos activos.
    - Si faltan, crea los que hagan falta en posiciones aleatorias arriba.
    - Usa el 'meteor_bonus' de la IA para que, a medida que avanza el juego,
      los meteoritos nuevos caigan un poquito más rápido.
    - Devuelve un NUEVO 'estado' con la tupla de meteoros repuesta y
      la semilla actualizada.
    """
    from dataclasses import replace
    from .rng import azar_en_rango

    s = estado.semilla_azar
    mets = list(estado.meteoros)

    # Mientras haya menos de 8 meteoros, añadimos nuevos en la parte superior.
    while len(mets) < 8:
        s, nx = azar_en_rango(s, 0, ANCHO - 40)
        s, ny = azar_en_rango(s, -140, -100)
        s, sx = azar_en_rango(s, -3, 3)
        s, sy = azar_en_rango(s, 1 + estado.ia.meteor_bonus, 4 + estado.ia.meteor_bonus)
        mets.append(EstadoMeteoro(nx, ny, sx, sy))

    # Devolvemos un estado NUEVO (replace) con meteoros como tupla e
    # inyectamos la semilla actualizada para la próxima vez.
    return replace(estado, meteoros=tuple(mets), semilla_azar=s)
