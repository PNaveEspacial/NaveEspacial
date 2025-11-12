from dataclasses import replace
from typing import Tuple
from .constantes import (
    PLAYER_W, PLAYER_H, ENEMY_W, ENEMY_H, BOSS_W, BOSS_H,
    BULLET_W, BULLET_H, EBULLET_W, EBULLET_H
)
from .geom import _rects_collide
from .estados import EstadoJuego, EstadoExplosion
from .enums_eventos import Evento, EventoTipo
from .jugador import _daño, _tick_invul


def _con_eventos(estado: EstadoJuego, *evs: Evento) -> EstadoJuego:
    """
    Devuelve una COPIA del estado pero agregando eventos.
    Esto nos sirve para avisarle a la cáscara imperativa cosas como:
    - “el jefe entró”
    - “el jugador murió”
    Sin efectos secundarios: solo devolvemos un nuevo estado.
    """
    return replace(estado, eventos=estado.eventos + evs)


def detectar_colisiones(estado: EstadoJuego) -> EstadoJuego:
    """
    Colisiones en el modo “meteoritos”:
    - Balas del jugador vs meteoritos (sumamos puntaje y creamos explosión)
    - Meteoritos vs jugador (aplicamos daño con invulnerabilidad de ~5s)
    - Limpiamos balas que ya chocaron
    Nota: todo es INMUTABLE, siempre retornamos un NUEVO estado.
    """
    puntaje = estado.puntaje
    meteoros_vivos = []
    balas_rest = []
    fx = list(estado.explosiones)  # acumulamos FX nuevas aquí

    # --- balas del jugador contra meteoritos ---
    for m in estado.meteoros:
        golpeado = False
        for b in estado.balas:
            if _rects_collide(b.x, b.y, BULLET_W, BULLET_H, m.x, m.y, m.ancho, m.alto):
                # Si le damos a un meteoro: +10 puntos y una explosión visual
                puntaje += 10
                fx.append(EstadoExplosion(
                    x=m.x + m.ancho // 2,
                    y=m.y + m.alto // 2,
                    tipo="meteor",
                    timer=18
                ))
                golpeado = True
                break
        if not golpeado:
            # Solo conservamos los meteoritos que no fueron destruidos
            meteoros_vivos.append(m)

    # --- conservar balas que NO chocaron con ningún meteoro ---
    for b in estado.balas:
        hay_impacto = False
        for m in estado.meteoros:
            if _rects_collide(b.x, b.y, BULLET_W, BULLET_H, m.x, m.y, m.ancho, m.alto):
                hay_impacto = True
                break
        if not hay_impacto:
            balas_rest.append(b)

    # --- meteoritos chocando contra el jugador ---
    j = estado.jugador
    prev_vivo = j.vivo
    recibio = False
    for m in meteoros_vivos:
        if _rects_collide(j.x, j.y, PLAYER_W, PLAYER_H, m.x, m.y, m.ancho, m.alto):
            # _daño respeta la invulnerabilidad: si ya está invulnerable, NO baja vida.
            j = _daño(j, 1)   # por defecto deja 300 frames (~5s) de invulnerabilidad
            recibio = True
            break

    # Si este frame NO recibió golpe, simplemente descontamos 1 frame de invulnerabilidad
    if not recibio:
        j = _tick_invul(j)

    # Armamos el nuevo estado con TODO actualizado
    nuevo = replace(
        estado,
        jugador=j,
        meteoros=tuple(meteoros_vivos),
        balas=tuple(balas_rest),
        puntaje=puntaje,
        explosiones=tuple(fx)
    )

    # Si pasó de vivo -> muerto, mandamos evento para que la cáscara actúe (sonido, pantalla, etc.)
    if prev_vivo and not j.vivo:
        return _con_eventos(nuevo, Evento(EventoTipo.JUGADOR_MUERTO))
    return nuevo


def detectar_colisiones_enemigo(estado: EstadoJuego) -> EstadoJuego:
    """
    Colisiones cuando hay ENEMIGOS:
    - Balas del jugador vs enemigos (mata, suma puntos y deja explosión temporizada)
    - Balas enemigas vs jugador (aplica daño solo si NO está invulnerable)
    - Mantiene explosiones de enemigos hasta que terminen su temporizador
    """
    puntaje = estado.puntaje
    j = estado.jugador
    prev_vivo = j.vivo
    fx = list(estado.explosiones)

    # --- balas del jugador contra enemigos ---
    enemigos = list(estado.enemigos)
    balas_rest = []
    for b in estado.balas:
        impacto = False
        for idx, e in enumerate(enemigos):
            # Solo colisiona si está vivo, no explotando y ya sin protección de spawn
            if e.vivo and not e.explotando and e.spawn_protect == 0:
                if _rects_collide(b.x, b.y, BULLET_W, BULLET_H, e.x, e.y, ENEMY_W, ENEMY_H):
                    enemigos[idx] = replace(e, vivo=False, explotando=True, temporizador_explosion=10)
                    puntaje += 50
                    fx.append(EstadoExplosion(
                        x=e.x + ENEMY_W // 2,
                        y=e.y + ENEMY_H // 2,
                        tipo="enemy",
                        timer=18
                    ))
                    impacto = True
                    break
        if not impacto:
            balas_rest.append(b)

    # --- balas enemigas contra el jugador ---
    be_rest = []
    recibio = False
    for eb in estado.balas_enemigas:
        if _rects_collide(j.x, j.y, PLAYER_W, PLAYER_H, eb.x, eb.y, EBULLET_W, EBULLET_H):
            if j.invul_frames == 0:
                j = _daño(j, 1)  # activa invulnerabilidad (~5s) si no la tenía
            recibio = True
        else:
            be_rest.append(eb)

    if not recibio:
        j = _tick_invul(j)

    # --- mantener explosiones de enemigos hasta agotar temporizador ---
    enemigos_final = []
    for e in enemigos:
        if e.vivo:
            enemigos_final.append(e)
        elif e.explotando and e.temporizador_explosion > 0:
            enemigos_final.append(replace(e, temporizador_explosion=e.temporizador_explosion - 1))
        # Si explotó y el timer ya llegó a 0, simplemente desaparece (no lo agregamos)

    nuevo = replace(
        estado,
        jugador=j,
        enemigos=tuple(enemigos_final),
        balas=tuple(balas_rest),
        balas_enemigas=tuple(be_rest),
        puntaje=puntaje,
        explosiones=tuple(fx)
    )

    if prev_vivo and not j.vivo:
        return _con_eventos(nuevo, Evento(EventoTipo.JUGADOR_MUERTO))
    return nuevo


def detectar_colisiones_jefe(estado: EstadoJuego) -> EstadoJuego:
    """
    Colisiones contra el JEFE:
    - Balas del jugador vs jefe (baja vida del jefe)
    - Si la vida llega a 0, disparamos evento JEFE_MUERTO
    - Si nos ponen en modo JEFE pero no existe instancia -> evento ESTADO_INVALIDO
    """
    boss = estado.boss
    if boss is None:
        # Si el modo dice “JEFE” pero no hay jefe creado, lo reportamos como “estado inválido”
        from .enums_eventos import ModoJuego
        if estado.modo == ModoJuego.JEFE:
            return _con_eventos(estado, Evento(EventoTipo.ESTADO_INVALIDO, ("modo_jefe_sin_instancia",)))
        return estado

    if not boss.vivo:
        return estado

    puntaje = estado.puntaje  # (no sumamos aquí, pero mantenemos el patrón)
    balas_rest = []
    vida = boss.vida
    murio = False

    for b in estado.balas:
        if _rects_collide(b.x, b.y, BULLET_W, BULLET_H, boss.x, boss.y, BOSS_W, BOSS_H):
            # Cada bala del jugador le quita 10 de vida al jefe
            nv = max(0, vida - 10)
            murio = (vida > 0 and nv == 0)
            vida = nv
        else:
            balas_rest.append(b)

    boss = replace(boss, vida=vida, vivo=(vida > 0))
    nuevo = replace(estado, boss=boss, balas=tuple(balas_rest), puntaje=puntaje)

    # Si el jefe murió justo aquí, avisamos con un evento para que la cáscara haga sonido/FX
    return _con_eventos(nuevo, Evento(EventoTipo.JEFE_MUERTO)) if murio else nuevo


def avanzar_explosiones(estado: EstadoJuego) -> EstadoJuego:
    """
    Avanza el “timer” de todas las explosiones con HOFs:
    - filter: me quedo con las que siguen activas (timer > 0)
    - map: a cada una le resto 1 al timer
    Retorno una tupla nueva (inmutabilidad).
    """
    activas = filter(lambda e: e.timer > 0, estado.explosiones)
    nuevas = map(lambda e: replace(e, timer=e.timer - 1), activas)
    return replace(estado, explosiones=tuple(nuevas))
