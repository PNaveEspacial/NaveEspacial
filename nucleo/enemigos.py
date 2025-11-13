from dataclasses import replace
from typing import Tuple
from .constantes import ANCHO, ENEMY_W, ENEMY_H, EBULLET_W, ALTO
from .geom import _clamp
from .rng import azar_en_rango
from .estados import EstadoEnemigo, EstadoBalaEnemiga, EstadoJugador

def crear_enemigos(cant: int, semilla: int):
    """
    Crea una tupla de enemigos “alineados” en la parte superior.
    - Usamos la semilla para que la distribución sea determinista (estilo FP).
    - Cada enemigo arranca entrando desde arriba (y negativa) y baja hasta y_objetivo.
    - Definimos un rango de patrulla en X para que se muevan de lado a lado.

    Args:
        cant: cuántos enemigos queremos generar
        semilla: semilla del RNG del núcleo (sin usar random global)

    Returns:
        (enemigos, semilla_actualizada)
    """
    espacio = ANCHO // (cant + 1)  # separación uniforme en X
    enemigos = []
    s = semilla
    Y_LINEA = 90  # altura a la que “se estacionan” al terminar la entrada

    for i in range(cant):
        # posición “base” en X, centrada por ranuras
        x_ini = espacio * (i + 1) - ENEMY_W // 2

        # azar controlado para el ancho de patrulla y dirección inicial
        s, ancho_rango = azar_en_rango(s, 100, 140)
        s, dir_rand = azar_en_rango(s, 0, 1)

        # límites de patrulla y dirección de arranque
        min_x = _clamp(x_ini - ancho_rango // 2, 0, ANCHO - ENEMY_W)
        max_x = _clamp(x_ini + ancho_rango // 2, 0, ANCHO - ENEMY_W)
        dir_ini = 1 if dir_rand == 0 else -1

        # enemigo arrancando “desde arriba” (y negativa), con protección de spawn
        enemigos.append(EstadoEnemigo(
            x=x_ini, y=-ENEMY_H, velocidad_x=2, direccion=dir_ini,
            patrulla_min_x=min_x, patrulla_max_x=max_x,
            entrando=True, y_objetivo=Y_LINEA, spawn_protect=24
        ))

    return tuple(enemigos), s


def _indice_lider(enemigos: Tuple[EstadoEnemigo, ...], jugador: EstadoJugador) -> int:
    """
    Busca cuál enemigo está “más alineado” con el jugador en X
    (el más cercano horizontalmente a la nave).
    Ese será el “líder” que tratará de seguir al jugador.

    Returns:
        índice del líder o -1 si no hay vivos
    """
    vivos = [
        (i, abs((e.x + ENEMY_W // 2) - (jugador.x + 30)))  # 30 ≈ mitad nave jugador
        for i, e in enumerate(enemigos) if e.vivo and not e.explotando
    ]
    return min(vivos, key=lambda t: t[1])[0] if vivos else -1


def actualizar_enemigos_ia(enemigos: Tuple[EstadoEnemigo, ...], jugador: EstadoJugador, ia) -> Tuple[EstadoEnemigo, ...]:
    """
    Mueve enemigos con reglas simples:
    - Mientras “entran”: bajan hasta su y_objetivo y se mueven un poquito en X.
    - El líder intenta alinearse con el jugador.
    - El resto patrulla entre min_x y max_x rebotando en los bordes.
    - Pequeño “empuje” para que no se amontonen entre ellos (se separan en X).
    - Se reduce el spawn_protect de todos por frame.
    """
    if not enemigos:
        return enemigos

    idx_lider = _indice_lider(enemigos, jugador)
    provisional = list(enemigos)

    # 1) movimiento básico (entrada / líder / patrulla)
    for i, e in enumerate(enemigos):
        if not e.vivo:
            provisional[i] = e
            continue

        if e.entrando:
            # Entran de arriba hacia su línea objetivo
            ny = e.y + 2
            fin = ny >= e.y_objetivo
            dx_enter = 1 if e.direccion > 0 else -1  # pequeño corrimiento lateral mientras baja
            nx = _clamp(e.x + dx_enter, 0, ANCHO - ENEMY_W)
            provisional[i] = replace(e, x=nx, y=(e.y_objetivo if fin else ny), entrando=(not fin))
            continue

        if i == idx_lider:
            # El “líder” busca la X del jugador (con tope por pantalla)
            objetivo = _clamp(jugador.x, 0, ANCHO - ENEMY_W)
            dx = 2 if objetivo > e.x else (-2 if objetivo < e.x else 0)
            nx = _clamp(e.x + dx, 0, ANCHO - ENEMY_W)
            provisional[i] = replace(e, x=nx)
        else:
            # Patrulla simple entre límites
            nx = e.x + e.velocidad_x * e.direccion
            nd = e.direccion
            if nx <= e.patrulla_min_x:
                nx = e.patrulla_min_x; nd = 1
            elif nx >= e.patrulla_max_x:
                nx = e.patrulla_max_x; nd = -1
            provisional[i] = replace(e, x=nx, direccion=nd)

    # 2) “Separación” para que no se peguen demasiado (evita solapamientos feos)
    sep_min = ENEMY_W * 0.8  # distancia mínima deseada en X
    empuje = 1               # cuánto corregimos por frame
    final = list(provisional)

    for i in range(len(provisional)):
        e_i = provisional[i]
        # Solo aplicamos si está en escena (no entrando) y vivo
        if not (e_i.vivo and not e_i.entrando and not e_i.explotando):
            continue

        ex, ey = e_i.x, e_i.y
        corr = 0
        for j in range(len(provisional)):
            if i == j:
                continue
            e_j = provisional[j]
            if not (e_j.vivo and not e_j.explotando):
                continue

            ox, oy = e_j.x, e_j.y
            # Si están muy cerca en X y más o menos a la misma altura, empujamos
            if abs(ex - ox) < sep_min and abs(ey - oy) < ENEMY_H:
                corr += (empuje if ex <= ox else -empuje)

        if corr != 0:
            nx = _clamp(ex - corr, 0, ANCHO - ENEMY_W)
            # Evita que se queden “pegados” a los extremos si ya estaban en borde
            if (nx == 0 and corr > 0) or (nx == ANCHO - ENEMY_W and corr < 0):
                nx = ex
            final[i] = replace(final[i], x=nx)

    # 3) Reducimos la protección de spawn (después de unos frames ya pueden recibir daño)
    return tuple(replace(e, spawn_protect=max(0, e.spawn_protect - 1)) for e in final)


def logica_disparo_enemigo(enemigos: Tuple[EstadoEnemigo, ...], semilla: int, ia, x_predicho: int):
    """
    Genera disparos enemigos de forma “semi-inteligente”:
    - Solo disparan si el jugador (predicho) está más o menos alineado en X.
    - La ventana de alineación y el cooldown dependen de la dificultad.
    - Todo se hace con la semilla (sin random global).
    """
    nuevas = []
    s = semilla
    # Ventana de alineación: con más dificultad, más estricta
    ventana = max(40, 140 - int(ia.dificultad * 8))
    actualizados = []

    for e in enemigos:
        if not e.vivo or e.explotando:
            actualizados.append(e)
            continue

        # bajamos el cooldown frame a frame
        cd = max(0, e.cooldown - 1)
        # ¿Está el jugador (predicho) más o menos enfrente?
        alineado = abs(x_predicho - (e.x + ENEMY_W // 2)) < ventana
        disparo = False

        if cd == 0 and alineado and (not e.entrando) and (e.spawn_protect == 0):
            disparo = True
            # calculamos un nuevo cooldown pseudoaleatorio basado en dificultad
            base_min = max(12, 26 - int(ia.dificultad * 3))
            base_max = max(base_min + 2, 36 - int(ia.dificultad * 2))
            s, cd = azar_en_rango(s, base_min, base_max)

        if disparo:
            cx = e.x + ENEMY_W // 2 - EBULLET_W // 2
            vel = 6 + int(ia.dificultad * 0.5)
            nuevas.append(EstadoBalaEnemiga(x=cx, y=e.y + ENEMY_H - 8, velocidad_y=vel))

        actualizados.append(replace(e, cooldown=cd))

    return tuple(actualizados), tuple(nuevas), s


def actualizar_balas_enemigas(balas: Tuple[EstadoBalaEnemiga, ...]) -> Tuple[EstadoBalaEnemiga, ...]:
    """
    Avanza las balas enemigas de forma FUNCIONAL:
    - filter: me quedo solo con las que siguen “en cámara” (o un poco fuera)
    - map: muevo cada bala según su velocidad (sin mutar nada)
    """
    # Filtra las balas dentro de pantalla (un margen para que no “desaparezcan” de golpe)
    dentro = filter(lambda b: (b.y < ALTO + 60) and (-40 <= b.x <= ANCHO + 40), balas)
    # Aplica un desplazamiento funcional a cada bala (crea copias con replace)
    movidas = map(lambda b: replace(b, x=b.x + b.velocidad_x, y=b.y + b.velocidad_y), dentro)
    return tuple(movidas)