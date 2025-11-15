from dataclasses import replace
from .constantes import ENEMY_WAVE_COOLDOWN, MIXED_WAVE_COOLDOWN, PREBOSS_PAUSE_TICKS
from .enums_eventos import Evento, EventoTipo, ModoJuego
from .estados import EstadoJuego, EstadoMeteoro, EstadoJugador, EstadoIA
from .rng import azar_en_rango
from .enemigos import crear_enemigos
from .jefe import crear_jefe

# ============================================================================
# flujo.py — Orquestador del NÚCLEO (puro)
# Aquí se decide “qué pasa después” según el modo, puntaje e IA.
# No hay I/O ni efectos: solo creamos NUEVOS estados inmutables.
# ============================================================================

def _con_eventos(estado: EstadoJuego, *evs: Evento) -> EstadoJuego:
    """
    Agrega eventos que la cáscara (UI/sonido) escuchará luego.
    Ej: JEFE_ENTRA, JUGADOR_MUERTO. Mantiene la pureza: el núcleo
    solo “emite” eventos como datos, y afuera reaccionan.
    """
    return replace(estado, eventos=estado.eventos + evs)

def _todos_fuera(enemigos) -> bool:
    """
    Devuelve True si ya no quedan enemigos “activos” en pantalla
    (ni vivos ni explotando). Sirve para saber cuándo lanzar otra oleada.
    """
    return all((not e.vivo) and (not e.explotando) for e in enemigos)

def logica_juego(estado: EstadoJuego) -> EstadoJuego:
    """
    Máquina de estados del juego:
    - Pasa de METEORITOS → ENEMIGOS cuando el puntaje lo permita.
    - En ENEMIGOS, al llegar al umbral (mix_threshold) cambia a MIXTO.
    - En MIXTO, alterna oleadas de enemigos y mete una pausa antes del JEFE.
    - En JEFE, cuando muere, reinicia ciclo con más dificultad.
    Todo de forma pura, devolviendo un NUEVO EstadoJuego.
    """
    ia = estado.ia

    # --- 1) Cambio a ENEMIGOS cuando ya hay puntaje suficiente ---
    if estado.modo == ModoJuego.METEORITOS and estado.puntaje >= 300:
        enemigos, s = crear_enemigos(ia.siguiente_tam, estado.semilla_azar)
        ia2 = replace(ia, oleada=1, wave_cooldown=0)
        return replace(estado, modo=ModoJuego.ENEMIGOS, enemigos=enemigos, semilla_azar=s, meteoros=tuple(), ia=ia2)

    # --- 2) Cambio a MIXTO cuando se supera el umbral de la IA ---
    if estado.modo == ModoJuego.ENEMIGOS and estado.puntaje >= ia.mix_threshold:
        enemigos, s = crear_enemigos(5, estado.semilla_azar)
        nuevo_ia = replace(ia, mixed_waves_spawned=1, wave_cooldown=0, reponer_meteoros=True, preboss_pause=0)
        return replace(estado, modo=ModoJuego.MIXTO, enemigos=enemigos, semilla_azar=s, ia=nuevo_ia)

    # --- 3) Bucle de oleadas en ENEMIGOS (sin meteoros) ---
    if estado.modo == ModoJuego.ENEMIGOS:
        if _todos_fuera(estado.enemigos):
            # cooldown entre oleadas
            if ia.wave_cooldown > 0:
                return replace(estado, ia=replace(ia, wave_cooldown=ia.wave_cooldown - 1))
            # aumenta dificultad y lanza nueva oleada
            nueva_dif = min(10, ia.dificultad + 0.6)
            tam = 5
            enemigos, s = crear_enemigos(tam, estado.semilla_azar)
            ia3 = replace(ia, dificultad=nueva_dif, velocidad_reaccion=1.0 + (nueva_dif / 3),
                          oleada=ia.oleada + 1, siguiente_tam=tam, wave_cooldown=ENEMY_WAVE_COOLDOWN)
            return replace(estado, enemigos=enemigos, semilla_azar=s, ia=ia3)
        return estado

    # --- 4) Modo MIXTO: alterna oleadas y prepara al JEFE ---
    if estado.modo == ModoJuego.MIXTO:
        # Espera a que no queden enemigos
        if not _todos_fuera(estado.enemigos): 
            return estado

        # (a) Aún faltan rondas mixtas → generar otra oleada
        if ia.mixed_waves_spawned < ia.mixed_rounds_target:
            if ia.wave_cooldown > 0:
                return replace(estado, ia=replace(ia, wave_cooldown=ia.wave_cooldown - 1))
            enemigos, s = crear_enemigos(5, estado.semilla_azar)
            return replace(estado, enemigos=enemigos, semilla_azar=s,
                           ia=replace(ia, mixed_waves_spawned=ia.mixed_waves_spawned + 1,
                                      reponer_meteoros=True, wave_cooldown=MIXED_WAVE_COOLDOWN))

        # (b) Ya se cumplieron rondas → quitar reposición y activar pausa pre-JEFE
        if ia.reponer_meteoros:
            ia = replace(ia, reponer_meteoros=False, preboss_pause=PREBOSS_PAUSE_TICKS)
            return replace(estado, ia=ia)

        # (c) Contador de pausa antes del JEFE
        if ia.preboss_pause > 0:
            return replace(estado, ia=replace(ia, preboss_pause=ia.preboss_pause - 1))

        # (d) Instanciar JEFE y notificar evento (la cáscara pone música/FX)
        if estado.boss is None:
            nuevo = replace(estado, modo=ModoJuego.JEFE, boss=crear_jefe(), meteoros=tuple())
            return _con_eventos(nuevo, Evento(EventoTipo.JEFE_ENTRA))
        return estado

    # --- 5) Al matar al JEFE: subir dificultad y reiniciar ciclo MIXTO ---
    if estado.modo == ModoJuego.JEFE and (estado.boss is not None) and (not estado.boss.vivo):
        nueva_dif = min(10, ia.dificultad + 1.0)
        nuevo_ia = replace(ia, dificultad=nueva_dif, velocidad_reaccion=1.0 + (nueva_dif / 3),
                           meteor_bonus=min(5, ia.meteor_bonus + 1),
                           mixed_waves_spawned=0, reponer_meteoros=True, preboss_pause=0,
                           wave_cooldown=0, cycles=ia.cycles + 1)
        return replace(estado, modo=ModoJuego.MIXTO, enemigos=tuple(), boss=None, ia=nuevo_ia)

    # Si nada aplica, el estado sigue igual
    return estado

def inicializar_juego(semilla: int = 42) -> EstadoJuego:
    """
    Crea el estado inicial: meteoroides aleatorios, jugador centrado,
    IA en valores base y sin jefe. Todo inmutable y listo para testear.
    """
    meteoros = []
    s = semilla
    from .constantes import ANCHO
    for _ in range(8):
        s, nx = azar_en_rango(s, 0, ANCHO - 40)
        s, ny = azar_en_rango(s, -140, -100)
        s, sx = azar_en_rango(s, -3, 3)
        s, sy = azar_en_rango(s, 1, 4)
        meteoros.append(EstadoMeteoro(nx, ny, sx, sy))

    from .constantes import ALTO
    jugador = EstadoJugador(ANCHO // 2, ALTO - 50, 7, True, 0)

    ia = EstadoIA(
        dificultad=1.0, velocidad_reaccion=1.0, ultimo_x_jugador=ANCHO // 2,
        oleada=0, siguiente_tam=3, wave_cooldown=0, mix_threshold=3000,
        mixed_waves_spawned=0, mixed_rounds_target=4, reponer_meteoros=True,
        preboss_pause=0, meteor_bonus=0, cycles=0
    )

    # Nota: Evento importado solo para tipado; no se crean eventos aquí.
    from .enums_eventos import Evento  # noqa: F401 (solo tipo)

    return EstadoJuego(
        jugador=jugador, meteoros=tuple(meteoros), balas=tuple(),
        enemigos=tuple(), balas_enemigas=tuple(), puntaje=0,
        semilla_azar=s, modo=ModoJuego.METEORITOS, ia=ia,
        boss=None, explosiones=tuple(), eventos=tuple()
    )

# ----------------------------------------------------------------------------
# Ajustes de “IA” mínimos y predicción básica del jugador
# Mantienen el bucle estable sin romper la pureza del núcleo.
# ----------------------------------------------------------------------------

def ajustar_ia(ia, puntaje: int, jugador_vivo: bool):
    """
    Sube MUY lento la dificultad si el jugador sigue vivo.
    Devolvemos una NUEVA IA (dataclass) con la dificultad ajustada.
    """
    try:
        inc = 0.002 if jugador_vivo else 0.0
        nueva_dif = min(10.0, ia.dificultad + inc)
        return replace(ia, dificultad=nueva_dif)
    except Exception:
        # Por si llegara un tipo inesperado en tests/uso externo
        return ia

def predecir_jugador(ia, jugador):
    """
    “Predicción” simple: copiar el x actual del jugador a la IA.
    Devuelve (ia_actualizada, x_predicho). Sirve para disparos enemigos.
    """
    try:
        ia2 = replace(ia, ultimo_x_jugador=jugador.x)
    except Exception:
        ia2 = ia
    return ia2, getattr(jugador, "x", 0)