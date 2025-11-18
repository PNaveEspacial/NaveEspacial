# cascara_imperativa/records.py
import os
from typing import Dict, Tuple, List

# Archivo de récords junto al paquete
RECORDS_PATH = os.path.join(os.path.dirname(__file__), "records.txt")

# En memoria: nombre_normalizado -> (nombre_mostrado, mejor_puntaje)
_best: Dict[str, Tuple[str, int]] = {}
_loaded: bool = False  # para cargar una sola vez


def _norm_name(n: str) -> str:
    return (n or "").strip().lower()


def _ensure_loaded() -> None:
    """Lee de disco una sola vez. No escribe ni reinicia nada aquí."""
    global _loaded, _best
    if _loaded:
        return

    best: Dict[str, Tuple[str, int]] = {}
    if os.path.exists(RECORDS_PATH):
        try:
            with open(RECORDS_PATH, "r", encoding="utf-8") as f:
                for linea in f:
                    linea = linea.strip()
                    if not linea:
                        continue
                    partes = linea.rsplit("|", 1)
                    if len(partes) != 2:
                        continue
                    nombre, p = partes[0], partes[1]
                    try:
                        punt = int(p)
                    except:
                        continue
                    key = _norm_name(nombre)
                    prev = best.get(key)
                    if prev is None or punt > prev[1]:
                        best[key] = (nombre, punt)
        except Exception:
            best = {}

    _best = best
    _loaded = True


def cargar_records() -> None:
    """
    Asegura que los récords estén cargados en memoria.
    No borra ni reescribe el archivo.
    """
    _ensure_loaded()


def _write_all() -> None:
    """
    Escribe TODOS los récords al archivo ordenados desc por puntaje.
    Usa archivo temporal para evitar corrupción.
    """
    tmp_path = RECORDS_PATH + ".tmp"
    try:
        pares: List[Tuple[str, int]] = sorted(_best.values(), key=lambda x: x[1], reverse=True)
        with open(tmp_path, "w", encoding="utf-8") as f:
            for nombre, punt in pares:
                f.write(f"{nombre}|{punt}\n")
        # Reemplazo atómico
        if os.path.exists(RECORDS_PATH):
            os.replace(tmp_path, RECORDS_PATH)
        else:
            os.rename(tmp_path, RECORDS_PATH)
    except Exception:
        try:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
        except:
            pass


def guardar_record(nombre: str, puntaje: int) -> None:
    """
    Actualiza el mejor puntaje del jugador (si es mayor) y persiste en disco.
    No borra a otros jugadores.
    """
    _ensure_loaded()
    key = _norm_name(nombre)
    prev = _best.get(key)
    if prev is None or int(puntaje) > prev[1]:
        _best[key] = ((nombre or "Jugador").strip(), int(puntaje))
        _write_all()


def top3() -> List[Tuple[str, int]]:
    """Devuelve el Top 3: lista de (nombre, puntaje) ordenados desc."""
    _ensure_loaded()
    return sorted(_best.values(), key=lambda x: x[1], reverse=True)[:3]


def todos() -> List[Tuple[str, int]]:
    """(Opcional) Devuelve todos los récords ordenados desc."""
    _ensure_loaded()
    return sorted(_best.values(), key=lambda x: x[1], reverse=True)