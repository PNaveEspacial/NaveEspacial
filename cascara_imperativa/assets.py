import pygame, os

def cargar_imagen(ruta, tam=None, colorkey=None):
    try:
        img = pygame.image.load(ruta).convert_alpha()
    except pygame.error:
        img = pygame.image.load(ruta).convert()
        if colorkey:
            img.set_colorkey(colorkey)
    else:
        if img.get_alpha() is None and colorkey:
            img.set_colorkey(colorkey)
    if tam:
        img = pygame.transform.scale(img, tam)
    return img

def cargar_fondo_cover(ruta, ancho, alto):
    img = pygame.image.load(ruta).convert()
    iw, ih = img.get_size()
    escala = max(ancho/iw, alto/ih)
    nw, nh = int(iw*escala), int(ih*escala)
    img = pygame.transform.smoothscale(img, (nw, nh))
    x = max(0, (nw-ancho)//2); y = max(0, (nh-alto)//2)
    return img.subsurface((x, y, ancho, alto)).copy()

def _cargar_corazon():
    """
    Intenta cargar primero assets/heart_pixel.png, luego assets/heart.png.
    Devuelve la superficie o None si no existe.
    """
    base = os.path.dirname(__file__)
    # El juego corre desde el directorio raíz del proyecto, por lo que
    # las rutas "assets/..." son relativas a ese working directory.
    path1 = os.path.join("assets", "heart_pixel.png")
    path2 = os.path.join("assets", "heart.png")
    path = path1 if os.path.exists(path1) else (path2 if os.path.exists(path2) else None)
    if not path:
        print("[ui_styles] No se encontró assets/heart_pixel.png")
        return None
    try:
        return pygame.image.load(path).convert_alpha()
    except:
        img = pygame.image.load(path).convert()
        img.set_colorkey((0,0,0))
        return img

def cargar_recursos(ANCHO, ALTO):
    """Devuelve un dict con todas las superficies/imágenes necesarias."""
    NEGRO = (0, 0, 0)

    fondo_menu = cargar_fondo_cover("assets/PantallaPrincipal.png", ANCHO, ALTO)
    fondo = pygame.transform.scale(pygame.image.load("assets/background.png").convert(), (ANCHO, ALTO))
    ambiente = pygame.transform.scale(pygame.image.load("assets/ambiente.png").convert(), (ANCHO, ALTO))

    img_jugador = cargar_imagen("assets/player.png", (60, 60))
    imgs_meteoros = [cargar_imagen("assets/meteorGrey_small1.png", (50, 50), NEGRO)]
    img_bala = cargar_imagen("assets/laser1.png", (10, 25))
    img_bala_enemiga = cargar_imagen("assets/balaenemiga.png", (12, 25), (255, 255, 255))
    img_enemigo = cargar_imagen("assets/enemigo.png", (60, 60), (255, 255, 255))

    # imagen de corazón (opcional)
    heart_img = _cargar_corazon()

    recursos = dict(
        fondo_menu=fondo_menu, fondo=fondo, ambiente=ambiente,
        img_jugador=img_jugador, imgs_meteoros=imgs_meteoros,
        img_bala=img_bala, img_bala_enemiga=img_bala_enemiga,
        img_enemigo=img_enemigo, heart_img=heart_img
    )
    return recursos
