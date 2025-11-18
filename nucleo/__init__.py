# Reexporta todo lo que espera shooter_app.py

from .constantes     import *            # <-- aquí viene BOSS_HP
from .enums_eventos   import ModoJuego, EventoTipo, Evento
from .estados        import *
from .rng            import siguiente_semilla, azar_en_rango
from .geom           import _rects_collide, _clamp

from .jugador        import mover_jugador, disparar_bala, actualizar_balas
from .meteoritos     import actualizar_meteoros, reponer_meteoros
from .enemigos       import actualizar_enemigos_ia, logica_disparo_enemigo, actualizar_balas_enemigas
from .jefe           import crear_jefe, actualizar_jefe, disparo_jefe
from .colisiones     import detectar_colisiones, detectar_colisiones_enemigo, detectar_colisiones_jefe, avanzar_explosiones
from .flujo          import inicializar_juego, logica_juego, ajustar_ia, predecir_jugador   # <-- ¡aquí!
from .flujo import inicializar_juego, logica_juego, ajustar_ia, predecir_jugador


__all__ = [
    "ModoJuego", "EventoTipo", "Evento",
    # constantes usadas fuera (incluye BOSS_HP):
    "BOSS_W", "BOSS_H", "BOSS_HP",
    # estados:
    "EstadoJuego", "EstadoJugador", "EstadoMeteoro", "EstadoEnemigo",
    "EstadoBala", "EstadoBalaEnemiga", "EstadoBoss", "EstadoIA", "EstadoExplosion",
    # rng / geom:
    "siguiente_semilla", "azar_en_rango", "_rects_collide", "_clamp",
    # jugador:
    "mover_jugador", "disparar_bala", "actualizar_balas",
    # meteoritos:
    "actualizar_meteoros", "reponer_meteoros",
    # enemigos:
    "actualizar_enemigos_ia", "logica_disparo_enemigo", "actualizar_balas_enemigas",
    # jefe:
    "crear_jefe", "actualizar_jefe", "disparo_jefe",
    # colisiones:
    "detectar_colisiones", "detectar_colisiones_enemigo", "detectar_colisiones_jefe", "avanzar_explosiones",
    # flujo / IA:
    "inicializar_juego", "logica_juego", "ajustar_ia", "predecir_jugador",
]