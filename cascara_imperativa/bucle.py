import pygame
from dataclasses import replace
from .audio import play_sound, iniciar_musica, parar_musica
from .pantallas import (
    mostrar_menu, mostrar_instrucciones, mostrar_records,
    mostrar_pantalla_game_over, mostrar_pausa, pedir_nombre
)
from .renderizado import dibujar_escena
from .records import cargar_records, guardar_record, top3
from .assets import cargar_imagen
from .estilos_ui import Button, draw_text, draw_title_plain

# Importa todo lo necesario del núcleo funcional
from nucleo import *

def _nueva_partida():
    estado = inicializar_juego()
    return estado, 24  # frames de gracia

def ejecutar_juego(pantalla, reloj, recursos, sonidos, ANCHO=800, ALTO=600):
    iniciar_musica(True)

    # --- Menú inicial ---
    while True:
        accion = mostrar_menu(pantalla, recursos["fondo_menu"], ANCHO)
        if accion == "salir":
            pygame.quit(); raise SystemExit
        elif accion == "instrucciones":
            mostrar_instrucciones(pantalla, recursos["fondo_menu"], ANCHO, ALTO); continue
        elif accion == "records":
            cargar_records(); mostrar_records(pantalla, recursos["fondo_menu"], ANCHO, ALTO, top3); continue
        elif accion == "jugar":
            jugador_actual = pedir_nombre(pantalla, reloj, recursos["fondo_menu"], ANCHO, ALTO)
            break

    estado, gracia_spawn = _nueva_partida()

    # fondos
    fondo_actual = recursos["fondo"]
    fondo_siguiente = None
    ambiente = recursos["ambiente"]
    fondo = recursos["fondo"]
    alfa_transicion, en_transicion = 0, False
    fondo_y1, fondo_y2 = 0, -ALTO

    prev_fx_ids = set()
    FIRE_RATE_FRAMES = 6
    fire_cooldown = 0

    # intenta cargar boss y explosiones si existen
    try:
        recursos["img_boss"] = cargar_imagen("assets/enemigofinal.png", (BOSS_W, BOSS_H), (0, 0, 0))
    except Exception:
        try:
            recursos["img_boss"] = pygame.transform.scale(recursos["img_enemigo"], (BOSS_W, BOSS_H))
        except Exception:
            recursos["img_boss"] = None
    try:
        recursos["img_explosion_enemy"] = cargar_imagen("assets/regularExplosion00.png")
    except Exception:
        recursos["img_explosion_enemy"] = None
    try:
        recursos["img_explosion_meteor"] = cargar_imagen("assets/regularExplosion01.png")
    except Exception:
        recursos["img_explosion_meteor"] = None

    corriendo = True
    while corriendo:
        reloj.tick(60)
        teclas = pygame.key.get_pressed()

        # Entrada
        jugador = estado.jugador
        if teclas[pygame.K_LEFT]:  jugador = mover_jugador(jugador, -1)
        if teclas[pygame.K_RIGHT]: jugador = mover_jugador(jugador,  1)

        balas = estado.balas
        balas_enemigas = estado.balas_enemigas
        ia = ajustar_ia(estado.ia, estado.puntaje, estado.jugador.vivo)

        # Eventos / Pausa
        esc_pulsado = False
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                corriendo = False
            if e.type == pygame.KEYDOWN and e.key == pygame.K_ESCAPE:
                esc_pulsado = True

        if esc_pulsado and estado.jugador.vivo:
            botones = [
                Button("REANUDAR",  220, 160, 360, 70, "resume",  theme="neon"),
                Button("REINICIAR", 220, 254, 360, 70, "restart", theme="neon"),
                Button("SALIR",     220, 348, 360, 70, "exit",    theme="neon"),
            ]
            accion_pausa = mostrar_pausa(pantalla, ANCHO, ALTO, draw_title_plain=draw_title_plain, botones=botones, reloj=reloj)
            if accion_pausa == "restart":
                estado, gracia_spawn = _nueva_partida()
                fondo_actual, fondo_siguiente = fondo, None
                alfa_transicion, en_transicion = 0, False
                prev_fx_ids = set()
                fire_cooldown = 0
                iniciar_musica(True)
            elif accion_pausa == "exit":
                while True:
                    accion = mostrar_menu(pantalla, recursos["fondo_menu"], ANCHO)
                    if accion == "salir": pygame.quit(); raise SystemExit
                    if accion == "instrucciones": mostrar_instrucciones(pantalla, recursos["fondo_menu"], ANCHO, ALTO); continue
                    if accion == "records": cargar_records(); mostrar_records(pantalla, recursos["fondo_menu"], ANCHO, ALTO, top3); continue
                    if accion == "jugar":
                        jugador_actual = pedir_nombre(pantalla, reloj, recursos["fondo_menu"], ANCHO, ALTO)
                        iniciar_musica(True)
                        estado, gracia_spawn = _nueva_partida()
                        fondo_actual, fondo_siguiente = fondo, None
                        alfa_transicion, en_transicion = 0, False
                        prev_fx_ids = set()
                        fire_cooldown = 0
                        break

        # Disparo continuo
        if fire_cooldown > 0:
            fire_cooldown -= 1
        if teclas[pygame.K_SPACE] and fire_cooldown <= 0 and estado.jugador.vivo:
            balas = disparar_bala(jugador, balas)
            play_sound(sonidos["laser"], 0.55)
            fire_cooldown = FIRE_RATE_FRAMES

        # --- Actualización por modo ---
        if estado.modo == ModoJuego.METEORITOS:
            balas = actualizar_balas(balas)
            meteoros, sem = actualizar_meteoros(estado.meteoros, estado.semilla_azar, estado.ia.meteor_bonus)
            tmp = replace(estado, jugador=jugador, meteoros=meteoros, balas=balas, semilla_azar=sem, ia=ia)
            tmp = detectar_colisiones(tmp)
            estado = reponer_meteoros(tmp)

        elif estado.modo in (ModoJuego.ENEMIGOS, ModoJuego.MIXTO):
            balas = actualizar_balas(balas)
            ia, x_pred = predecir_jugador(ia, jugador)
            enemigos = actualizar_enemigos_ia(estado.enemigos, jugador, ia)
            balas_enemigas = actualizar_balas_enemigas(estado.balas_enemigas)
            enemigos2, nuevas_be, sem = logica_disparo_enemigo(enemigos, estado.semilla_azar, ia, x_pred)
            if len(nuevas_be) == 0: sem, _ = siguiente_semilla(sem)
            todas_be = balas_enemigas + nuevas_be
            tmp = replace(estado, jugador=jugador, enemigos=enemigos2, balas=balas,
                          balas_enemigas=todas_be, semilla_azar=sem, ia=ia)
            tmp = detectar_colisiones_enemigo(tmp)
            if tmp.modo == ModoJuego.MIXTO:
                mets, sem2 = actualizar_meteoros(tmp.meteoros, tmp.semilla_azar, tmp.ia.meteor_bonus)
                tmp = replace(tmp, meteoros=mets, semilla_azar=sem2)
                tmp = detectar_colisiones(tmp)
                tmp = reponer_meteoros(tmp)
            estado = tmp

        elif estado.modo == ModoJuego.JEFE:
            balas = actualizar_balas(balas)
            balas_enemigas = actualizar_balas_enemigas(estado.balas_enemigas)
            boss = actualizar_jefe(estado.boss, jugador)
            boss, nuevas_boss = disparo_jefe(boss, ia)
            todas_be = balas_enemigas + nuevas_boss
            tmp = replace(estado, jugador=jugador, balas=balas, balas_enemigas=todas_be, boss=boss, ia=ia)
            if tmp.meteoros:
                mets, sem2 = actualizar_meteoros(tmp.meteoros, tmp.semilla_azar, tmp.ia.meteor_bonus)
                tmp = replace(tmp, meteoros=mets, semilla_azar=sem2)
                tmp = detectar_colisiones(tmp)
            tmp = detectar_colisiones_enemigo(tmp)
            estado = detectar_colisiones_jefe(tmp)

        # FX + lógica global
        estado = avanzar_explosiones(estado)
        estado = logica_juego(estado)

        # Gracia de spawn
        if gracia_spawn > 0:
            gracia_spawn -= 1
            estado = replace(
                estado,
                jugador=replace(estado.jugador, corazones=7, vivo=True, invul_frames=max(estado.jugador.invul_frames, 10))
            )

        # Eventos del núcleo
        if estado.eventos:
            for ev in estado.eventos:
                if ev.tipo == EventoTipo.JEFE_ENTRA:
                    play_sound(sonidos["alerta"], 0.35)
                elif ev.tipo == EventoTipo.JEFE_MUERTO:
                    play_sound(sonidos["explosion_enemy"], 0.75)
            estado = replace(estado, eventos=tuple())

        # Scroll y transiciones
        velocidad_scroll = 2 if estado.modo == ModoJuego.METEORITOS else 4
        fondo_y1 += velocidad_scroll; fondo_y2 += velocidad_scroll
        if fondo_y1 >= ALTO: fondo_y1 = -ALTO
        if fondo_y2 >= ALTO: fondo_y2 = -ALTO

        if not en_transicion:
            if estado.modo == ModoJuego.METEORITOS and fondo_actual is not fondo:
                fondo_siguiente, en_transicion, alfa_transicion = fondo, True, 0
            elif estado.modo in (ModoJuego.ENEMIGOS, ModoJuego.MIXTO, ModoJuego.JEFE) and fondo_actual is not ambiente:
                fondo_siguiente, en_transicion, alfa_transicion = ambiente, True, 0

        if en_transicion and fondo_siguiente:
            alfa_transicion += 5
            if alfa_transicion >= 255:
                alfa_transicion, en_transicion = 255, False
                fondo_actual, fondo_siguiente = fondo_siguiente, None
            pantalla.blit(fondo_actual, (0, fondo_y1))
            pantalla.blit(fondo_actual, (0, fondo_y2))
            if fondo_siguiente:
                t1 = fondo_siguiente.copy(); t2 = fondo_siguiente.copy()
                t1.set_alpha(alfa_transicion); t2.set_alpha(alfa_transicion)
                pantalla.blit(t1, (0, fondo_y1)); pantalla.blit(t2, (0, fondo_y2))
        else:
            pantalla.blit(fondo_actual, (0, fondo_y1))
            pantalla.blit(fondo_actual, (0, fondo_y2))

        # Render + HUD
        fx_birth_now = dibujar_escena(pantalla, estado, recursos, prev_fx_ids, HUD=True, BOSS_HP=BOSS_HP, ANCHO=ANCHO, ALTO=ALTO)

        # Sonidos de explosión al nacer
        for key in fx_birth_now:
            if key not in prev_fx_ids:
                _, _, tipo = key
                if tipo == "meteor":
                    play_sound(sonidos["explosion_meteor"], 0.6)
                else:
                    play_sound(sonidos["explosion_enemy"], 0.65)
        prev_fx_ids = fx_birth_now

        # Indicador de modo
        draw_text(pantalla, f"Modo: {estado.modo.value}", 70, 36, size=18, anchor="center")

        pygame.display.flip()

        # Game Over
               
        if not estado.jugador.vivo:
            # ← GUARDA el record antes de la pantalla Game Over
            guardar_record(jugador_actual, estado.puntaje)

            parar_musica()
            acc = mostrar_pantalla_game_over(
                pantalla, recursos["fondo_menu"], ANCHO, ALTO, estado.puntaje,
                draw_text=draw_text,
                draw_title_plain=draw_title_plain,
                reloj=reloj
            )
            if acc == "reiniciar":
                estado, gracia_spawn = _nueva_partida()
                fondo_actual, fondo_siguiente = fondo, None
                alfa_transicion, en_transicion = 0, False
                prev_fx_ids = set()
                fire_cooldown = 0
                iniciar_musica(True)
            else:
                cargar_records()
                while True:
                    accion = mostrar_menu(pantalla, recursos["fondo_menu"], ANCHO)
                    if accion == "salir":
                        pygame.quit()
                        raise SystemExit
                    if accion == "instrucciones":
                        mostrar_instrucciones(pantalla, recursos["fondo_menu"], ANCHO, ALTO)
                        continue
                    if accion == "records":
                        mostrar_records(pantalla, recursos["fondo_menu"], ANCHO, ALTO, top3)
                        continue
                    if accion == "jugar":
                        jugador_actual = pedir_nombre(pantalla, reloj, recursos["fondo_menu"], ANCHO, ALTO)
                        iniciar_musica(True)
                        estado, gracia_spawn = _nueva_partida()
                        fondo_actual, fondo_siguiente = fondo, None
                        alfa_transicion, en_transicion = 0, False
                        prev_fx_ids = set()
                        fire_cooldown = 0
                        break