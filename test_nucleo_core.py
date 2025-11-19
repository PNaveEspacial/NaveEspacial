# tests/test_nucleo_core.py
# Pruebas unitarias del núcleo funcional (paquete: nucleo)
# Ejecuta:  pytest -q

import math
from dataclasses import replace

import pytest

from nucleo.constantes import (
    ANCHO, ALTO,
    PLAYER_W, PLAYER_H, ENEMY_W, ENEMY_H,
    BULLET_W, BULLET_H, EBULLET_W, EBULLET_H,
    BOSS_W, BOSS_H, BOSS_HP,
)

from nucleo.enums_eventos import ModoJuego, EventoTipo
from nucleo.geom import _rects_collide, _clamp
from nucleo.rng import siguiente_semilla, azar_en_rango

from nucleo.estados import (
    EstadoJugador, EstadoMeteoro, EstadoBala,
    EstadoBalaEnemiga, EstadoEnemigo, EstadoBoss,
    EstadoExplosion, EstadoIA, EstadoJuego
)

from nucleo.jugador import mover_jugador, disparar_bala, actualizar_balas, _daño, _tick_invul
from nucleo.meteoritos import actualizar_meteoros, reponer_meteoros
from nucleo.enemigos import crear_enemigos, actualizar_enemigos_ia, logica_disparo_enemigo, actualizar_balas_enemigas
from nucleo.jefe import crear_jefe, actualizar_jefe, disparo_jefe
from nucleo.colisiones import detectar_colisiones, detectar_colisiones_enemigo, detectar_colisiones_jefe, avanzar_explosiones
from nucleo.flujo import inicializar_juego, logica_juego, ajustar_ia, predecir_jugador


# -----------------------------
# RNG
# -----------------------------
def test_siguiente_semilla_determinista():
    s1 = 42
    s2, r2 = siguiente_semilla(s1)
    s3, r3 = siguiente_semilla(s1)
    assert s2 == s3 and r2 == r3

def test_azar_en_rango_inclusivo():
    s = 123
    for _ in range(100):
        s, v = azar_en_rango(s, 5, 9)
        assert 5 <= v <= 9


# -----------------------------
# Geometría utilitaria
# -----------------------------
def test_rects_collide_basico():
    assert _rects_collide(0, 0, 10, 10, 5, 5, 10, 10)  # se solapan
    assert not _rects_collide(0, 0, 10, 10, 11, 0, 10, 10)  # separados

def test_clamp():
    assert _clamp(5, 0, 10) == 5
    assert _clamp(-1, 0, 10) == 0
    assert _clamp(11, 0, 10) == 10


# -----------------------------
# Jugador
# -----------------------------
def test_mover_jugador_limites():
    j = EstadoJugador(x=0, y=ALTO-50, corazones=7, vivo=True, invul_frames=0)
    j2 = mover_jugador(j, -1)
    assert j2.x == 0  # borde izq
    j3 = mover_jugador(j, +1000)
    assert j3.x == ANCHO - PLAYER_W  # borde der

def test_disparar_y_actualizar_balas():
    j = EstadoJugador(x=100, y=500, corazones=7, vivo=True, invul_frames=0)
    balas = tuple()
    balas = disparar_bala(j, balas)
    assert len(balas) == 1
    assert balas[0].y == 500
    balas2 = actualizar_balas(balas)
    assert balas2[0].y < balas[0].y  # sube (velocidad negativa)

def test_danio_e_invulnerabilidad():
    j = EstadoJugador(x=0, y=0, corazones=3, vivo=True, invul_frames=0)
    j2 = _daño(j, 1, invul=2)
    assert j2.corazones == 2 and j2.vivo and j2.invul_frames == 2
    # mientras hay invul, _daño no reduce corazones
    j3 = _daño(j2, 1, invul=2)
    assert j3.corazones == 2
    # tick invul reduce frames hasta 0
    j4 = _tick_invul(j3)
    j5 = _tick_invul(j4)
    assert j5.invul_frames == 0


# -----------------------------
# Meteoritos
# -----------------------------
def test_actualizar_y_reponer_meteoros():
    mets = (EstadoMeteoro(10, 10, 0, 1),)
    nuevos, s = actualizar_meteoros(mets, semilla_azar=42, bonus_vel=0)
    assert len(nuevos) == 1
    # reponer meteoro hasta tener 8
    estado = EstadoJuego(
        jugador=EstadoJugador(ANCHO//2, ALTO-50, 7, True, 0),
        meteoros=tuple(),
        balas=tuple(),
        enemigos=tuple(),
        balas_enemigas=tuple(),
        puntaje=0,
        semilla_azar=42,
        modo=ModoJuego.METEORITOS,
        ia=EstadoIA(dificultad=1.0, velocidad_reaccion=1.0, ultimo_x_jugador=0),
        boss=None,
        explosiones=tuple(),
        eventos=tuple()
    )
    estado2 = reponer_meteoros(estado)
    assert len(estado2.meteoros) >= 8


# -----------------------------
# Enemigos
# -----------------------------
def _ia_basica():
    return EstadoIA(
        dificultad=1.0, velocidad_reaccion=1.0, ultimo_x_jugador=ANCHO//2,
        oleada=0, siguiente_tam=3, wave_cooldown=0, mix_threshold=3000,
        mixed_waves_spawned=0, mixed_rounds_target=4, reponer_meteoros=True,
        preboss_pause=0, meteor_bonus=0, cycles=0
    )

def test_crear_enemigos():
    enemigos, s = crear_enemigos(4, 42)
    assert len(enemigos) == 4
    assert all(0 <= e.x <= ANCHO - ENEMY_W for e in enemigos)

def test_actualizar_enemigos_ia_movimiento():
    enemigos, _ = crear_enemigos(3, 42)
    jugador = EstadoJugador(100, 500, 7, True, 0)
    ia = _ia_basica()
    new_enemigos = actualizar_enemigos_ia(enemigos, jugador, ia)
    assert len(new_enemigos) == len(enemigos)

def test_logica_disparo_enemigo():
    enemigos, s = crear_enemigos(3, 42)
    # forzamos cd=0 y sin protección para permitir disparos
    enemigos = tuple(replace(e, cooldown=0, spawn_protect=0, entrando=False, y=80) for e in enemigos)
    ia = _ia_basica()
    ia2, predx = predecir_jugador(ia, EstadoJugador(ANCHO//2, 500, 7, True, 0))
    enemigos2, nuevas_be, s2 = logica_disparo_enemigo(enemigos, s, ia2, predx)
    assert len(enemigos2) == len(enemigos)
    assert s2 != s  # la semilla avanza
    # Puede o no haber disparos según alineación/ventana; al menos debe devolver tuplas
    assert isinstance(nuevas_be, tuple)

def test_actualizar_balas_enemigas_fuera_limites():
    be = (EstadoBalaEnemiga(x=10, y=ALTO+100, velocidad_y=6),)  # fuera
    res = actualizar_balas_enemigas(be)
    assert len(res) == 0


# -----------------------------
# Jefe
# -----------------------------
def test_crear_y_entrar_jefe():
    boss = crear_jefe()
    assert boss.vivo and boss.entrando
    # Simula avance hasta llegar a y_objetivo
    j = EstadoJugador(ANCHO//2, ALTO-50, 7, True, 0)
    for _ in range(100):
        boss = actualizar_jefe(boss, j)
    assert not boss.entrando and boss.y == boss.y_objetivo

def test_disparo_jefe_basico():
    boss = crear_jefe()
    ia = _ia_basica()
    # llévalo a posición de combate
    boss = replace(boss, entrando=False, y=boss.y_objetivo, fase="rest", fase_timer=0, cooldown=0)
    boss2, balas = disparo_jefe(boss, ia)
    # Puede entrar en "burst" y disparar 0 o 2 balas según temporización;
    assert isinstance(balas, tuple)
    assert boss2 is not None


# -----------------------------
# Colisiones
# -----------------------------
def _estado_basico():
    jugador = EstadoJugador(ANCHO//2, ALTO-60, 7, True, 0)
    ia = _ia_basica()
    return EstadoJuego(
        jugador=jugador,
        meteoros=tuple(),
        balas=tuple(),
        enemigos=tuple(),
        balas_enemigas=tuple(),
        puntaje=0,
        semilla_azar=42,
        modo=ModoJuego.METEORITOS,
        ia=ia,
        boss=None,
        explosiones=tuple(),
        eventos=tuple()
    )

def test_colision_meteoro_bala_y_puntaje():
    e = _estado_basico()
    # Un meteoro y una bala que chocan
    m = EstadoMeteoro(100, 100, 0, 0, ancho=50, alto=50)
    b = EstadoBala(100, 100)
    e = replace(e, meteoros=(m,), balas=(b,))
    e2 = detectar_colisiones(e)
    assert len(e2.meteoros) == 0
    assert len(e2.balas) == 0
    assert e2.puntaje >= e.puntaje

def test_colision_enemigo_con_bala_y_con_bala_enemiga():
    # bala del jugador destruye enemigo
    j = EstadoJugador(100, 500, 7, True, 0)
    ene = EstadoEnemigo(100, 100, 0, 1, vivo=True, explotando=False, spawn_protect=0, entrando=False, y_objetivo=80)
    b = EstadoBala(100, 100)
    e = _estado_basico()
    e = replace(e, jugador=j, enemigos=(ene,), balas=(b,), modo=ModoJuego.ENEMIGOS)
    e2 = detectar_colisiones_enemigo(e)
    assert any(not en.vivo or en.explotando for en in e2.enemigos)
    # bala enemiga golpea al jugador
    be = EstadoBalaEnemiga(x=j.x, y=j.y)
    e3 = replace(e2, balas=tuple(), balas_enemigas=(be,))
    e4 = detectar_colisiones_enemigo(e3)
    assert e4.jugador.corazones <= j.corazones

def test_colision_jefe_con_balas():
    boss = EstadoBoss(x=100, y=100, vida=20, vivo=True, entrando=False, y_objetivo=20)
    b1 = EstadoBala(x=100, y=100)  # impacta
    e = _estado_basico()
    e = replace(e, boss=boss, balas=(b1,), modo=ModoJuego.JEFE)
    e2 = detectar_colisiones_jefe(e)
    # puede que la vida llegue a 10 o 0 según el daño fijo (10)
    assert e2.boss.vida in (10, 0)
    if e2.boss.vida == 0:
        # debería haber evento JEFE_MUERTO
        assert any(ev.tipo == EventoTipo.JEFE_MUERTO for ev in e2.eventos)

def test_avanzar_explosiones_decrementa_timers():
    fx = (EstadoExplosion(x=0, y=0, tipo="meteor", timer=2),)
    e = _estado_basico()
    e2 = replace(e, explosiones=fx)
    e3 = avanzar_explosiones(e2)
    assert e3.explosiones[0].timer == 1


# -----------------------------
# Flujo / IA
# -----------------------------
def test_inicializar_juego_basico():
    e = inicializar_juego(semilla=42)
    assert e.modo == ModoJuego.METEORITOS
    assert len(e.meteoros) >= 1
    assert e.jugador.vivo

def test_ajustar_ia_y_predecir():
    e = inicializar_juego()
    ia2 = ajustar_ia(e.ia, e.puntaje, True)
    assert ia2.dificultad >= e.ia.dificultad
    ia3, xpred = predecir_jugador(ia2, e.jugador)
    assert xpred == e.jugador.x
    assert ia3.ultimo_x_jugador == e.jugador.x

def test_logica_juego_transiciones_sin_romper():
    # partimos de METEORITOS con puntaje bajo: no cambia
    e = inicializar_juego()
    e2 = logica_juego(e)
    assert e2.modo in (ModoJuego.METEORITOS, ModoJuego.ENEMIGOS, ModoJuego.MIXTO, ModoJuego.JEFE)

    # fuerza transición a ENEMIGOS incrementando puntaje
    e_alto = replace(e, puntaje=1000)
    e3 = logica_juego(e_alto)
    assert e3.modo in (ModoJuego.ENEMIGOS, ModoJuego.MIXTO, ModoJuego.JEFE)
