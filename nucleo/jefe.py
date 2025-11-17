from dataclasses import replace
from typing import Tuple
from .constantes import ANCHO, BOSS_W, BOSS_H, EBULLET_W, BOSS_HP
from .geom import _clamp
from .estados import EstadoBoss, EstadoBalaEnemiga, EstadoJugador

def crear_jefe() -> EstadoBoss:
    """
    Crea el jefe al inicio de su aparición:
      - Entra desde arriba (y = -BOSS_H) hasta y_objetivo
      - Empieza vivo, en fase "rest" (descanso) con temporizadores en 0
    """
    return EstadoBoss(x=ANCHO//2 - BOSS_W//2, y=-BOSS_H, vida=BOSS_HP, vivo=True,
                      entrando=True, y_objetivo=20, fase="rest", fase_timer=0,
                      disparos_en_rafaga=0, cooldown=0)

def actualizar_jefe(boss: EstadoBoss, jugador: EstadoJugador) -> EstadoBoss:
    """
    Actualiza la posición/temporizadores del jefe de forma PURA:
      - Si está entrando: baja hasta y_objetivo y cambia a fase "rest"
      - Si ya está en combate: sigue al jugador en X suavemente
      - Disminuye cooldown y fase_timer en cada tick (si son > 0)
    """
    if not boss.vivo: 
        return boss

    # Animación de entrada (baja desde fuera de pantalla)
    if boss.entrando:
        ny = boss.y + 3
        if ny >= boss.y_objetivo:
            ny = boss.y_objetivo
            # Al terminar la entrada, queda en reposo un ratito
            return replace(boss, y=ny, entrando=False, fase="rest", fase_timer=30, cooldown=0)
        return replace(boss, y=ny, cooldown=0)

    # En combate: tick de temporizadores (no bajan de 0)
    nuevo_cd = boss.cooldown - 1 if boss.cooldown > 0 else 0
    nuevo_timer = boss.fase_timer - 1 if boss.fase_timer > 0 else 0

    # Seguir al jugador en el eje X (pasos pequeños para que no sea brusco)
    cx = boss.x + BOSS_W//2
    objetivo = jugador.x + 30  # 30 ≈ mitad del jugador; lo centra un poco
    dx = 3 if objetivo > cx else (-3 if objetivo < cx else 0)
    nx = _clamp(boss.x + dx, 0, ANCHO - BOSS_W)

    return replace(boss, x=nx, cooldown=nuevo_cd, fase_timer=nuevo_timer)

def disparo_jefe(boss: EstadoBoss, ia) -> Tuple[EstadoBoss, Tuple[EstadoBalaEnemiga, ...]]:
    """
    Lógica de disparo del jefe (pura):
      - Dos fases:
          "rest": descansa hasta que se agota fase_timer, luego cambia a "burst"
          "burst": dispara en parejas (izq+der). Cuando alcanza el máximo, vuelve a "rest"
      - La dificultad del juego (ia.dificultad) ajusta cadencia, pausa y cantidad de disparos
      - Devuelve (nuevo_boss, balas_nuevas) sin efectos secundarios
    """
    if not boss.vivo or boss.entrando:
        return boss, tuple()

    # Ajustes dinámicos según dificultad (más difícil → más rápido/más disparos)
    cad_base = max(6, boss.cadencia_frames - int(ia.dificultad * 0.3))   # tiempo entre disparos
    pausa_base = max(36, boss.pausa_frames - int(ia.dificultad * 1.5))   # descanso entre ráfagas
    max_pairs  = min(16, boss.max_disparos_rafaga + int(ia.dificultad * 0.5))

    # Fase de descanso: esperar a que el temporizador llegue a 0
    if boss.fase == "rest":
        if boss.fase_timer > 0:
            return boss, tuple()
        # Cambia a ráfaga y reinicia contador
        boss = replace(boss, fase="burst", disparos_en_rafaga=0, cooldown=0)

    # Fase de ráfaga: dispara en parejas desde los “cañones” izquierdo y derecho
    if boss.fase == "burst":
        if boss.cooldown > 0:
            return boss, tuple()

        # Coordenadas de salida de balas (dos cañones)
        left_x  = boss.x + 28
        right_x = boss.x + BOSS_W - 28 - EBULLET_W
        y       = boss.y + BOSS_H - 10
        vel     = 6 + int(ia.dificultad * 0.5)

        balas = (
            EstadoBalaEnemiga(x=left_x,  y=y, velocidad_y=vel),
            EstadoBalaEnemiga(x=right_x, y=y, velocidad_y=vel)
        )

        # Contar parejas disparadas en la ráfaga actual
        disparos = boss.disparos_en_rafaga + 1

        # ¿Se terminó la ráfaga? → volver a "rest" con una pausa
        if disparos >= max_pairs:
            boss = replace(boss, fase="rest", fase_timer=pausa_base,
                           disparos_en_rafaga=0, cooldown=cad_base)
        else:
            # Todavía quedan disparos en la ráfaga → poner cooldown corto
            boss = replace(boss, disparos_en_rafaga=disparos, cooldown=cad_base)

        return boss, balas

    # Si por alguna razón la fase no coincide con ninguna (seguro), no dispara
    return boss, tuple()