import pygame

def play_sound(snd, vol=1.0):
    try:
        ch = pygame.mixer.find_channel(True)
        if ch:
            ch.set_volume(vol)
            ch.play(snd)
    except Exception:
        pass

def cargar_sonidos():
    sonidos = {}
    sonidos["laser"] = pygame.mixer.Sound("assets/laser5.ogg"); sonidos["laser"].set_volume(0.55)
    sonidos["explosion_enemy"] = pygame.mixer.Sound("assets/explosion.wav"); sonidos["explosion_enemy"].set_volume(0.65)
    try:
        sonidos["explosion_meteor"] = pygame.mixer.Sound("assets/explision.wav")
    except Exception:
        sonidos["explosion_meteor"] = pygame.mixer.Sound("assets/explosion.wav")
    sonidos["explosion_meteor"].set_volume(0.6)
    sonidos["alerta"] = pygame.mixer.Sound("assets/laser5.ogg"); sonidos["alerta"].set_volume(0.35)

    pygame.mixer.music.load("assets/music.ogg")
    pygame.mixer.music.set_volume(0.18)
    return sonidos

def iniciar_musica(loop=True):
    try:
        pygame.mixer.music.play(loops=-1 if loop else 0)
    except Exception:
        pass

def parar_musica():
    try:
        pygame.mixer.music.stop()
    except Exception:
        pass
