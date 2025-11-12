import pygame
from cascara_imperativa.assets import cargar_recursos
from cascara_imperativa.audio import cargar_sonidos
from cascara_imperativa.bucle import ejecutar_juego
from cascara_imperativa.estilos_ui import set_heart_image

def main():
    pygame.init()
    pygame.mixer.init()
    pygame.mixer.set_num_channels(64)

    ANCHO, ALTO = 800, 600
    pantalla = pygame.display.set_mode((ANCHO, ALTO))
    pygame.display.set_caption("Los Hombres Funcionales")
    reloj = pygame.time.Clock()

    recursos = cargar_recursos(ANCHO, ALTO)
    # Inyecta el corazón cargado a la UI
    set_heart_image(recursos.get("heart_img"))

    sonidos = cargar_sonidos()
    ejecutar_juego(pantalla, reloj, recursos, sonidos, ANCHO=ANCHO, ALTO=ALTO)

if __name__ == "__main__":
    main()
