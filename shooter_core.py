# shooter_core.py
# Núcleo funcional puro del juego Shooter (versión básica funcional)
from dataclasses import dataclass, replace
from typing import List, Tuple

ANCHO = 800
ALTO = 600
PLAYER_W, PLAYER_H = 60, 60
BULLET_W, BULLET_H = 10, 25

# ============================================================
# 🧩 ESTRUCTURAS INMUTABLES
# ============================================================
@dataclass(frozen=True)
class EstadoJugador:
    x: int
    y: int
    escudo: int
    vivo: bool

@dataclass(frozen=True)
class EstadoMeteoro:
    x: int
    y: int
    velocidad_x: int
    velocidad_y: int
    ancho: int = 50
    alto: int = 50

@dataclass(frozen=True)
class EstadoBala:
    x: int
    y: int
    velocidad_y: int = -10
    activa: bool = True

@dataclass(frozen=True)
class EstadoJuego:
    jugador: EstadoJugador
    meteoros: List[EstadoMeteoro]
    balas: List[EstadoBala]
    puntaje: int
    semilla_azar: int

# ============================================================
# 🔀 RNG FUNCIONAL
# ============================================================
def siguiente_semilla(semilla: int) -> Tuple[int, int]:
    nueva = (semilla * 1664525 + 1013904223) % 2**32
    return nueva, nueva

def azar_en_rango(semilla: int, a: int, b: int) -> Tuple[int, int]:
    nueva, r = siguiente_semilla(semilla)
    return nueva, a + (r % (b - a + 1))

# ============================================================
# 🚀 Movimiento y disparo del jugador
# ============================================================
def _clamp(v, a, b): return max(a, min(b, v))

def mover_jugador(jugador: EstadoJugador, direccion: int) -> EstadoJugador:
    nuevo_x = _clamp(jugador.x + direccion * 5, 0, ANCHO - PLAYER_W)
    return replace(jugador, x=nuevo_x)

def disparar_bala(jugador: EstadoJugador, balas: List[EstadoBala]) -> List[EstadoBala]:
    bx = jugador.x + (PLAYER_W // 2 - BULLET_W // 2)
    return balas + [EstadoBala(x=bx, y=jugador.y)]

def actualizar_balas(balas: List[EstadoBala]) -> List[EstadoBala]:
    return [replace(b, y=b.y + b.velocidad_y) for b in balas if b.y > -40]

# ============================================================
# ☄️ Meteoros
# ============================================================
def actualizar_meteoros(meteoros: List[EstadoMeteoro], semilla_azar: int) -> Tuple[List[EstadoMeteoro], int]:
    nuevos, s = [], semilla_azar
    for m in meteoros:
        nx, ny = m.x + m.velocidad_x, m.y + m.velocidad_y
        if ny > ALTO + 10 or nx < -40 or nx > ANCHO + 40:
            s, rx = azar_en_rango(s, 0, ANCHO - m.ancho)
            s, ry = azar_en_rango(s, -140, -100)
            s, sx = azar_en_rango(s, -3, 3)
            s, sy = azar_en_rango(s, 1, 4)
            nuevos.append(EstadoMeteoro(rx, ry, sx, sy))
        else:
            nuevos.append(EstadoMeteoro(nx, ny, m.velocidad_x, m.velocidad_y))
    return nuevos, s

# ============================================================
# 💥 Colisiones
# ============================================================
def _rects_collide(ax, ay, aw, ah, bx, by, bw, bh):
    return (ax < bx + bw) and (ax + aw > bx) and (ay < by + bh) and (ay + ah > by)

def detectar_colisiones(estado: EstadoJuego) -> EstadoJuego:
    puntaje = estado.puntaje
    meteoros_vivos, balas_rest = [], []

    for m in estado.meteoros:
        golpeado = any(_rects_collide(b.x, b.y, BULLET_W, BULLET_H, m.x, m.y, m.ancho, m.alto) for b in estado.balas)
        if golpeado:
            puntaje += 10
        else:
            meteoros_vivos.append(m)

    for b in estado.balas:
        if not any(_rects_collide(b.x, b.y, BULLET_W, BULLET_H, m.x, m.y, m.ancho, m.alto) for m in estado.meteoros):
            balas_rest.append(b)

    j = estado.jugador
    impacto_j = any(_rects_collide(j.x, j.y, PLAYER_W, PLAYER_H, m.x, m.y, m.ancho, m.alto) for m in meteoros_vivos)
    if impacto_j:
        j = replace(j, escudo=max(0, j.escudo - 25))
    j = replace(j, vivo=j.escudo > 0)

    return replace(estado, jugador=j, meteoros=meteoros_vivos, balas=balas_rest, puntaje=puntaje)

# ============================================================
# 🔄 Flujo del juego
# ============================================================
def reponer_meteoros(estado: EstadoJuego) -> EstadoJuego:
    s = estado.semilla_azar
    mets = estado.meteoros[:]
    while len(mets) < 8:
        s, nx = azar_en_rango(s, 0, ANCHO - 40)
        s, ny = azar_en_rango(s, -140, -100)
        s, sx = azar_en_rango(s, -3, 3)
        s, sy = azar_en_rango(s, 1, 4)
        mets.append(EstadoMeteoro(nx, ny, sx, sy))
    return replace(estado, meteoros=mets, semilla_azar=s)

def inicializar_juego(semilla: int = 42) -> EstadoJuego:
    meteoros, s = [], semilla
    for _ in range(8):
        s, nx = azar_en_rango(s, 0, ANCHO - 40)
        s, ny = azar_en_rango(s, -140, -100)
        s, sx = azar_en_rango(s, -3, 3)
        s, sy = azar_en_rango(s, 1, 4)
        meteoros.append(EstadoMeteoro(nx, ny, sx, sy))
    jugador = EstadoJugador(ANCHO // 2, ALTO - 50, 100, True)
    return EstadoJuego(jugador, meteoros, [], 0, s)
