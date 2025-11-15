from dataclasses import dataclass, field
from typing import Tuple, Optional
from .constantes import ANCHO, ENEMY_W, BOSS_W

# ============================================================================
# estados.py (núcleo de datos inmutables)
# Nota: usamos @dataclass(frozen=True) y tuplas para mantener inmutabilidad.
# Cada “cambio” se logra creando una NUEVA copia desde la lógica pura.
# ============================================================================

@dataclass(frozen=True)
class EstadoJugador:
    """
    Jugador del juego: posición, corazones (vida), estado vivo/muerto
    y contador de invulnerabilidad en frames (para evitar daño temporal).
    """
    x: int; y: int; corazones: int; vivo: bool
    invul_frames: int = 0

@dataclass(frozen=True)
class EstadoMeteoro:
    """
    Meteoro con posición, velocidad y tamaño básico para colisiones AABB.
    """
    x: int; y: int; velocidad_x: int; velocidad_y: int
    ancho: int = 50; alto: int = 50

@dataclass(frozen=True)
class EstadoBala:
    """
    Bala del jugador: avanza hacia arriba, puede marcarse como activa/inactiva.
    """
    x: int; y: int; velocidad_y: int = -10; activa: bool = True

@dataclass(frozen=True)
class EstadoBalaEnemiga:
    """
    Bala enemiga: permite movimiento en Y (y opcionalmente en X) y estado activo.
    """
    x: int; y: int
    velocidad_y: int = 6; velocidad_x: int = 0
    activa: bool = True

@dataclass(frozen=True)
class EstadoEnemigo:
    """
    Enemigo estándar: posición, dirección/patrulla, ciclo de explosión,
    cooldown de disparo y protección de aparición (spawn_protect).
    Incluye fase de “entrada” hasta llegar a y_objetivo.
    """
    x: int; y: int; velocidad_x: int; direccion: int
    vivo: bool = True; explotando: bool = False
    temporizador_explosion: int = 0
    patrulla_min_x: int = 0
    patrulla_max_x: int = ANCHO - ENEMY_W
    cooldown: int = 0
    spawn_protect: int = 18
    entrando: bool = True
    y_objetivo: int = 80

@dataclass(frozen=True)
class EstadoBoss:
    """
    Jefe final: vida/estado, entrada inicial hasta y_objetivo y
    pequeña máquina de estados para ráfagas (fase/cooldown/timers).
    """
    x: int; y: int; vida: int; vivo: bool = True
    entrando: bool = True; y_objetivo: int = 20
    cooldown: int = 0; fase: str = "rest"; fase_timer: int = 0
    disparos_en_rafaga: int = 0
    cadencia_frames: int = 8; pausa_frames: int = 60; max_disparos_rafaga: int = 10

@dataclass(frozen=True)
class EstadoExplosion:
    """
    Efecto visual de explosión con contador de vida en frames y tipo (“meteor”/“enemy”).
    """
    x: int; y: int; tipo: str; timer: int = 18  # "meteor" | "enemy"

@dataclass(frozen=True)
class EstadoIA:
    """
    Parámetros de dificultad y control de flujo/oleadas:
    umbrales para pasar a MIXTO y JEFE, reposición de meteoros,
    bonus de meteoros y número de ciclos completados.
    """
    dificultad: float; velocidad_reaccion: float; ultimo_x_jugador: int
    oleada: int = 0; siguiente_tam: int = 3; wave_cooldown: int = 0
    mix_threshold: int = 3000
    mixed_waves_spawned: int = 0
    mixed_rounds_target: int = 4
    reponer_meteoros: bool = True; preboss_pause: int = 0
    meteor_bonus: int = 0; cycles: int = 0

@dataclass(frozen=True)
class EstadoJuego:
    """
    Estado global del juego (la “fuente de la verdad”):
    agrupa jugador, meteoros, enemigos, balas, puntaje, modo, IA, jefe,
    explosiones y eventos que el núcleo emite para que la cáscara actúe.
    """
    from .enums_eventos import Evento
    from .enums_eventos import ModoJuego
    jugador: "EstadoJugador"
    meteoros: Tuple["EstadoMeteoro", ...]
    balas: Tuple["EstadoBala", ...]
    enemigos: Tuple["EstadoEnemigo", ...]
    balas_enemigas: Tuple["EstadoBalaEnemiga", ...]
    puntaje: int
    semilla_azar: int
    modo: "ModoJuego"
    ia: "EstadoIA"
    boss: Optional["EstadoBoss"] = None
    explosiones: Tuple["EstadoExplosion", ...] = field(default_factory=tuple)
    eventos: Tuple["Evento", ...] = field(default_factory=tuple)