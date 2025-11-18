def siguiente_semilla(semilla: int):
    nueva = (semilla * 1664525 + 1013904223) % 2**32
    return nueva, nueva

def azar_en_rango(semilla: int, a: int, b: int):
    nueva, r = siguiente_semilla(semilla)
    return nueva, a + (r % (b - a + 1))