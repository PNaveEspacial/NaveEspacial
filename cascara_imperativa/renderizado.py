import pygame
from .estilos_ui import draw_text, draw_hearts

def draw_boss_bar(surface, x, y, vida, total):
    w, h = 320, 14
    pct = 0 if total <= 0 else max(0.0, min(1.0, vida / float(total)))
    pygame.draw.rect(surface, (60, 60, 60), (x-2, y-2, w+4, h+4), border_radius=6)
    pygame.draw.rect(surface, (180, 0, 0), (x, y, int(w*pct), h), border_radius=4)
    pygame.draw.rect(surface, (230, 230, 230), (x, y, w, h), 2, border_radius=4)

def dibujar_escena(pantalla, estado, recursos, prev_fx_ids,
                   HUD=True, BOSS_HP=600, ANCHO=800, ALTO=600):
    # --- Jugador con efecto de daño (parpadeo si está invulnerable) ---
    jug = estado.jugador
    img_jugador = recursos["img_jugador"]

    if jug.invul_frames > 0:
        # Parpadeo más notorio (≈ 4 veces por segundo a 60 FPS)
        if (jug.invul_frames // 15) % 2 == 0:
            pantalla.blit(img_jugador, (jug.x, jug.y))
    else:
        pantalla.blit(img_jugador, (jug.x, jug.y))

    # --- Meteoros ---
    for m in estado.meteoros:
        pantalla.blit(recursos["imgs_meteoros"][0], (m.x, m.y))

    # --- Enemigos ---
    for ene in estado.enemigos:
        pantalla.blit(recursos["img_enemigo"], (ene.x, ene.y))

    # --- Boss ---
    if getattr(estado, "boss", None) is not None and estado.boss.vivo:
        img_boss = recursos.get("img_boss")
        if img_boss:
            pantalla.blit(img_boss, (estado.boss.x, estado.boss.y))
        draw_boss_bar(pantalla, ANCHO//2 - 160, 56, estado.boss.vida, BOSS_HP)

    # --- Balas ---
    for be in estado.balas_enemigas:
        pantalla.blit(recursos["img_bala_enemiga"], (be.x, be.y))
    for b in estado.balas:
        pantalla.blit(recursos["img_bala"], (b.x, b.y))

    # --- FX: nacimiento (para audio afuera) ---
    fx_birth_now = set()
    for fx in estado.explosiones:
        if fx.timer >= 17:
            key = (fx.x, fx.y, fx.tipo)
            fx_birth_now.add(key)

    # --- Explosiones (visual) ---
    img_explosion_enemy = recursos.get("img_explosion_enemy")
    img_explosion_meteor = recursos.get("img_explosion_meteor")

    for fx in estado.explosiones:
        t = 1.0 - (fx.timer / 18.0)
        base = img_explosion_meteor if fx.tipo == "meteor" else img_explosion_enemy
        if base is None:
            r = 28 if fx.tipo == "meteor" else 32
            color = (255, 200, 50, 200) if fx.tipo == "meteor" else (255, 120, 0, 200)
            circ = pygame.Surface((r*2, r*2), pygame.SRCALPHA)
            pygame.draw.circle(circ, color, (r, r), r)
            circ.set_alpha(int(255 * (1.0 - t)))
            pantalla.blit(circ, circ.get_rect(center=(fx.x, fx.y)))
            continue

        base_w, base_h = base.get_width(), base.get_height()
        scale = (0.65 + 0.20 * t) if fx.tipo == "meteor" else (0.70 + 0.25 * t)
        max_w, max_h = (72, 72) if fx.tipo == "meteor" else (84, 84)
        w = min(int(base_w * scale), max_w)
        h = min(int(base_h * scale), max_h)
        w = max(w, 2)
        h = max(h, 2)
        sprite = pygame.transform.smoothscale(base, (w, h)).copy()
        alpha = max(0, min(255, int(255 * (1.0 - t))))
        sprite.set_alpha(alpha)
        pantalla.blit(sprite, sprite.get_rect(center=(fx.x, fx.y)))

    # --- HUD ---
    if HUD:
        draw_text(pantalla, f"Puntaje: {estado.puntaje}", ANCHO//2, 8, size=24)
       #-- draw_text(pantalla, f"Dif: {estado.ia.dificultad:.1f}", 742, 8, size=18, anchor="topright")
        draw_hearts(pantalla, 12, 8, estado.jugador.corazones, max_hearts=7, size=22, spacing=6)

    return fx_birth_now