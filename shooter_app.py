# shooter_app.py
# Versión funcional básica (fondo, nave, meteoros, disparo y sonido)
import pygame, sys
from dataclasses import replace
from shooter_core import *

pygame.init()
pygame.mixer.init()

ANCHO, ALTO = 800, 600
NEGRO = (0, 0, 0)

pantalla = pygame.display.set_mode((ANCHO, ALTO))
pygame.display.set_caption("Los Hombres Funcionales")
reloj = pygame.time.Clock()

# ---------------------------------------------------------
# Carga de recursos (usa carpeta Recursos/)
# ---------------------------------------------------------
def cargar_imagen(ruta, tam=None):
    img = pygame.image.load(ruta).convert_alpha()
    if tam:
        img = pygame.transform.scale(img, tam)
    return img

# Imágenes
fondo = pygame.transform.scale(pygame.image.load("Recursos/background.png").convert(), (ANCHO, ALTO))
img_jugador = cargar_imagen("Recursos/player.png", (60, 60))
img_meteoro = cargar_imagen("Recursos/meteorGrey_small1.png", (50, 50))
img_bala = cargar_imagen("Recursos/laser1.png", (10, 25))

# Sonidos
pygame.mixer.music.load("Recursos/music.ogg")
pygame.mixer.music.set_volume(0.3)
pygame.mixer.music.play(-1)

sonido_laser = pygame.mixer.Sound("Recursos/laser5.ogg")
sonido_laser.set_volume(0.5)

# ---------------------------------------------------------
# Bucle principal
# ---------------------------------------------------------
def main():
    estado = inicializar_juego()
    corriendo = True

    while corriendo:
        reloj.tick(60)
        teclas = pygame.key.get_pressed()

        # Eventos
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                corriendo = False
            elif e.type == pygame.KEYDOWN and e.key == pygame.K_SPACE:
                estado = replace(estado, balas=disparar_bala(estado.jugador, estado.balas))
                sonido_laser.play()  # 🔊 sonido del disparo

        # Movimiento jugador
        jugador = estado.jugador
        if teclas[pygame.K_LEFT]:
            jugador = mover_jugador(jugador, -1)
        if teclas[pygame.K_RIGHT]:
            jugador = mover_jugador(jugador, 1)

        # Actualizaciones
        balas = actualizar_balas(estado.balas)
        meteoros, s = actualizar_meteoros(estado.meteoros, estado.semilla_azar)
        tmp = replace(estado, jugador=jugador, balas=balas, meteoros=meteoros, semilla_azar=s)
        estado = detectar_colisiones(tmp)
        estado = reponer_meteoros(estado)

        # Dibujar
        pantalla.blit(fondo, (0, 0))
        pantalla.blit(img_jugador, (estado.jugador.x, estado.jugador.y))
        for m in estado.meteoros:
            pantalla.blit(img_meteoro, (m.x, m.y))
        for b in estado.balas:
            pantalla.blit(img_bala, (b.x, b.y))

        pygame.display.flip()

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
