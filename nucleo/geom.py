def _rects_collide(ax, ay, aw, ah, bx, by, bw, bh):
    """
    Colisión AABB (Axis-Aligned Bounding Box).
    Compara dos rectángulos alineados a ejes:
      - Rect A en (ax, ay) con ancho/alto (aw, ah)
      - Rect B en (bx, by) con ancho/alto (bw, bh)
    Devuelve True si se están tocando/traslapando.
    """
    return (ax < bx + bw) and (ax + aw > bx) and (ay < by + bh) and (ay + ah > by)

def _clamp(v, a, b):
    """
    Limita (sujeta) el valor v al rango [a, b].
    - Si v < a → devuelve a
    - Si v > b → devuelve b
    - Si a ≤ v ≤ b → devuelve v
    Útil para no salirnos de la pantalla ni de límites.
    """
    return max(a, min(b, v))