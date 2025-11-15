from enum import Enum
from dataclasses import dataclass
from typing import Tuple

# ============================================================================
# enums_eventos.py
# Definimos “tipos” que representan estados globales del juego y eventos.
# La idea es evitar strings sueltos en el código y usar Enums/Dataclasses,
# así “los estados ilegales son irrepresentables” (FP-friendly).
# ============================================================================

class ModoJuego(Enum):
    """
    Modo actual del juego (flujo de oleadas):
    - METEORITOS: solo meteoritos (fase inicial).
    - ENEMIGOS: aparecen naves enemigas en oleadas.
    - MIXTO: enemigos + meteoritos, transición antes del jefe.
    - JEFE: aparece el jefe final.
    """
    METEORITOS = "meteoritos"
    ENEMIGOS   = "enemigos"
    MIXTO      = "mixto"
    JEFE       = "jefe"


class EventoTipo(Enum):
    """
    Tipos de eventos que el núcleo emite para que la cáscara decida qué hacer:
    - JEFE_ENTRA: el jefe va a aparecer (sirve para alertas/sonidos).
    - JEFE_MUERTO: el jefe fue derrotado (cambiar música, animaciones, etc).
    - JUGADOR_MUERTO: el jugador se quedó sin corazones (Game Over).
    - ESTADO_INVALIDO: algo no cuadra con el modo/estado (para debug/telemetría).
    """
    JEFE_ENTRA      = "jefe_entra"
    JEFE_MUERTO     = "jefe_muerto"
    JUGADOR_MUERTO  = "jugador_muerto"
    ESTADO_INVALIDO = "estado_invalido"


@dataclass(frozen=True)
class Evento:
    """
    Evento inmutable que viaja del núcleo hacia afuera (UI/Audio/Persistencia).
    - tipo: qué clase de evento es (ver EventoTipo)
    - detalle: info adicional opcional (tupla con datos simples)
    """
    tipo: EventoTipo
    detalle: Tuple = tuple()