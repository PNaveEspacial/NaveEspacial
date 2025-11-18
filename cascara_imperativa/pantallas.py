import pygame
from .estilos_ui import Button, draw_text, draw_title_plain

def pedir_nombre(pantalla, reloj, fondo_menu, ANCHO, ALTO):
    fuente_txt = pygame.font.SysFont("serif", 28)
    nombre, cursor_visible, tiempo_cursor, max_len = "", True, 0, 16
    while True:
        pantalla.blit(fondo_menu, (0, 0))
        draw_title_plain(pantalla, "INGRESA TU NOMBRE", ANCHO//2, 28, size=64)
        caja_w, caja_h = 420, 50
        caja = pygame.Rect(ANCHO//2 - caja_w//2, ALTO//2 - caja_h//2, caja_w, caja_h)
        pygame.draw.rect(pantalla, (30, 30, 60), caja, border_radius=10)
        pygame.draw.rect(pantalla, (190, 190, 220), caja, 2, border_radius=10)
        tiempo_cursor += reloj.get_time()
        cursor_visible = ((tiempo_cursor // 500) % 2 == 0)
        mostrar = (nombre + "_") if cursor_visible and len(nombre) < max_len else nombre
        timg = fuente_txt.render(mostrar, True, (255,255,255))
        pantalla.blit(timg, timg.get_rect(center=caja.center))
        draw_text(pantalla, "[ENTER] Aceptar   [ESC] Cancelar", ANCHO//2, ALTO//2 + 70, size=24)
        pygame.display.flip()
        for e in pygame.event.get():
            if e.type == pygame.QUIT: pygame.quit(); raise SystemExit
            if e.type == pygame.KEYDOWN:
                if e.key == pygame.K_RETURN: return nombre.strip() or "Jugador"
                elif e.key == pygame.K_ESCAPE: return "Jugador"
                elif e.key == pygame.K_BACKSPACE: nombre = nombre[:-1]
                else:
                    ch = e.unicode
                    if ch and ch.isprintable() and ch != "|" and len(nombre) < max_len:
                        nombre += ch

def _menu_botones_y(pantalla, ANCHO, top_y=10, margen=40, title_size=92):
    title_rect = draw_title_plain(pantalla, "NAVE", ANCHO//2, top_y, size=title_size)
    return title_rect.bottom + margen

def mostrar_menu(pantalla, fondo_menu, ANCHO):
    boton_w, boton_h = 360, 70
    espacio = 24
    paleta_neon = ((60, 255, 150), (70, 160, 255))
    pantalla.blit(fondo_menu, (0, 0))
    inicio_y = _menu_botones_y(pantalla, ANCHO, top_y=10, margen=40, title_size=92)
    cx = ANCHO // 2 - boton_w // 2
    botones = [
        Button("INICIAR",       cx, inicio_y + 0*(boton_h+espacio), boton_w, boton_h, "jugar",          theme="neon", neon_colors=paleta_neon),
        Button("INSTRUCCIONES", cx, inicio_y + 1*(boton_h+espacio), boton_w, boton_h, "instrucciones",  theme="neon", neon_colors=paleta_neon),
        Button("RECORDS",       cx, inicio_y + 2*(boton_h+espacio), boton_w, boton_h, "records",        theme="neon", neon_colors=paleta_neon),
        Button("SALIR",         cx, inicio_y + 3*(boton_h+espacio), boton_w, boton_h, "salir",          theme="neon", neon_colors=paleta_neon),
    ]
    while True:
        pantalla.blit(fondo_menu, (0, 0))
        _menu_botones_y(pantalla, ANCHO, top_y=10, margen=40, title_size=92)
        for e in pygame.event.get():
            if e.type == pygame.QUIT: return "salir"
            if e.type == pygame.KEYDOWN and e.key == pygame.K_ESCAPE: return "salir"
            for b in botones:
                accion = b.handle_event(e)
                if accion: return accion
        for b in botones: b.draw(pantalla)
        pygame.display.flip()

def mostrar_instrucciones(pantalla, fondo_menu, ANCHO, ALTO):
    lines = [
        "CONTROLES:",
        "← / →   Mover la nave",
        "ESPACIO Disparar (mantener para fuego continuo)",
        "ESC      Pausa (menú en partida)",
        "",
        "OBJETIVO:",
        "Esquiva meteoros, destruye enemigos y suma puntos.",
        "",
        "[ ENTER ] Volver al menú",
    ]
    fuente = pygame.font.SysFont("serif", 24)
    while True:
        pantalla.blit(fondo_menu, (0, 0))
        y0 = draw_title_plain(pantalla, "INSTRUCCIONES", ANCHO//2, 16, size=80).bottom + 18
        y = y0
        for li in lines:
            r = fuente.render(li, True, (255,255,255))
            pantalla.blit(r, (ANCHO//2 - r.get_width()//2, y))
            y += 34
        pygame.display.flip()
        for e in pygame.event.get():
            if e.type == pygame.QUIT: return
            if e.type == pygame.KEYDOWN and e.key in (pygame.K_RETURN, pygame.K_ESCAPE): return

def mostrar_records(pantalla, fondo_menu, ANCHO, ALTO, top3_callable):
    fuente = pygame.font.SysFont("serif", 24)
    while True:
        top = top3_callable()
        pantalla.blit(fondo_menu, (0, 0))
        y0 = draw_title_plain(pantalla, "RECORDS (TOP 3)", ANCHO//2, 16, size=80).bottom + 18
        if not top:
            t = fuente.render("Aún no hay puntajes.", True, (255,255,255))
            pantalla.blit(t, (ANCHO//2 - t.get_width()//2, y0))
        else:
            y = y0
            for i, (nombre, p) in enumerate(top, start=1):
                fila = fuente.render(f"{i:02d}. {nombre} — {p} pts", True, (255,255,255))
                pantalla.blit(fila, (ANCHO//2 - fila.get_width()//2, y))
                y += 32
        pie = fuente.render("[ ENTER ] Volver al menú", True, (255,255,255))
        pantalla.blit(pie, (ANCHO//2 - pie.get_width()//2, ALTO - 80))
        pygame.display.flip()
        for e in pygame.event.get():
            if e.type == pygame.QUIT: return
            if e.type == pygame.KEYDOWN and e.key in (pygame.K_RETURN, pygame.K_ESCAPE): return

def mostrar_pantalla_game_over(pantalla, fondo_menu, ANCHO, ALTO, puntaje, draw_text, draw_title_plain, reloj):
    pantalla.blit(fondo_menu, (0, 0))
    y0 = draw_title_plain(pantalla, "GAME OVER", ANCHO//2, 48, size=90).bottom + 18
    draw_text(pantalla, f"Tu puntaje: {puntaje}", ANCHO//2, y0 + 28, size=28)
    draw_text(pantalla, "ESPACIO = Reiniciar   |   ESC = Menú", ANCHO//2, y0 + 64, size=22)
    pygame.display.flip()
    while True:
        reloj.tick(60)
        for e in pygame.event.get():
            if e.type == pygame.QUIT: pygame.quit(); raise SystemExit
            if e.type == pygame.KEYDOWN:
                if e.key == pygame.K_SPACE: return "reiniciar"
                if e.key == pygame.K_ESCAPE: return "menu"

def mostrar_pausa(pantalla, ANCHO, ALTO, draw_title_plain, botones, reloj):
    overlay = pygame.Surface((ANCHO, ALTO), pygame.SRCALPHA)
    overlay.fill((10, 20, 35, 160))
    titulo_y = 40
    while True:
        reloj.tick(60)
        pantalla.blit(overlay, (0, 0))
        draw_title_plain(pantalla, "PAUSA", ANCHO//2, titulo_y, size=96)
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                pygame.quit(); raise SystemExit
            for b in botones:
                accion = b.handle_event(e)
                if accion:
                    return accion
        for b in botones: b.draw(pantalla)
        pygame.display.flip()