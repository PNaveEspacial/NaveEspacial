import pygame
import os
from math import sin

BLANCO = (255, 255, 255)

# =====================================================
# Corazón: se inyecta desde assets.py (evita rutas)
# =====================================================
_HEART_IMG = None

def set_heart_image(img):
    """Permite inyectar la imagen de corazón ya cargada (o None)."""
    global _HEART_IMG
    _HEART_IMG = img

def draw_hearts(surf, x, y, hearts, max_hearts=7, size=22, spacing=6):
    """
    Dibuja una fila de corazones:
      - 'hearts' llenos y el resto vacíos hasta 'max_hearts'.
      - Si no hay asset, usa cuadrados de color como fallback.
    """
    hearts = max(0, min(max_hearts, int(hearts)))
    if _HEART_IMG:
        full = pygame.transform.scale(_HEART_IMG, (size, size))
        empty = full.copy()
        shade = pygame.Surface((size, size), pygame.SRCALPHA)
        shade.fill((0, 0, 0, 150))
        empty.blit(shade, (0, 0), special_flags=pygame.BLEND_RGBA_SUB)
        for i in range(max_hearts):
            surf.blit(full if i < hearts else empty, (x + i*(size + spacing), y))
        return

    # Fallback sin imagen
    filled = pygame.Surface((size, size), pygame.SRCALPHA); filled.fill((220, 40, 60))
    empty  = pygame.Surface((size, size), pygame.SRCALPHA); empty.fill((90, 90, 100))
    for i in range(max_hearts):
        surf.blit(filled if i < hearts else empty, (x + i*(size + spacing), y))

# =====================================================
# Texto y títulos
# =====================================================
def draw_text(surf, text, x, y, size=32, color=BLANCO, bold=False, anchor="center"):
    font = pygame.font.SysFont("serif", size, bold=bold)
    img = font.render(text, True, color)
    rect = img.get_rect()
    setattr(rect, anchor, (x, y))
    surf.blit(img, rect)

def _vgrad(width, height, c1, c2, horizontal=False):
    s = pygame.Surface((width, height), pygame.SRCALPHA)
    if horizontal:
        for sx in range(width):
            t = sx / max(1, width - 1)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            pygame.draw.line(s, (r, g, b), (sx, 0), (sx, height))
    else:
        for sy in range(height):
            t = sy / max(1, height - 1)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            pygame.draw.line(s, (r, g, b), (0, sy), (width, sy))
    return s

def _rounded_rect(surface, color, rect, radius, width=0):
    pygame.draw.rect(surface, color, rect, width=width, border_radius=radius)

class Button:
    def __init__(self, text, x, y, w, h, action,
                 theme="neon",
                 skin_path=None,
                 neon_colors=((40, 255, 120), (40, 140, 255)),
                 text_color=(255, 255, 255)):
        self.text = text
        self.rect = pygame.Rect(x, y, w, h)
        self.action = action
        self.theme = theme
        self.skin_path = skin_path
        self.text_color = text_color

        self._hover = False
        self._pressed = False
        self._t = 0.0

        self._skin_img = None
        if theme == "image" and skin_path:
            try:
                self._skin_img = pygame.image.load(skin_path).convert_alpha()
            except:
                self._skin_img = None

        self.neon_c1, self.neon_c2 = neon_colors

    def _draw_neon(self, surf):
        x, y, w, h = self.rect
        r = min(18, h // 2)

        pulse = 0.0
        if self._hover:
            self._t = (self._t + 0.08) % 6.28318
            pulse = (sin(self._t) * 0.5 + 0.5) * 0.6 + 0.4

        base = pygame.Surface((w, h), pygame.SRCALPHA)
        _rounded_rect(base, (10, 18, 28, 220), base.get_rect(), r)
        surf.blit(base, (x, y))

        edge = pygame.Surface((w+6, h+6), pygame.SRCALPHA)
        _rounded_rect(edge, (0, 255, 220, 40 if self._hover else 25), edge.get_rect(), r+3)
        surf.blit(edge, (x-3, y-3))

        body = _vgrad(w-8, h-8, self.neon_c1, self.neon_c2, horizontal=True)
        _rounded_rect(body, (0, 0, 0, 0), body.get_rect(), r-4)
        surf.blit(body, (x+4, y+4), special_flags=pygame.BLEND_PREMULTIPLIED)

        glow = pygame.Surface((w-14, h-14), pygame.SRCALPHA)
        _rounded_rect(glow, (255, 255, 255, int(50 + 80 * pulse)), glow.get_rect(), r-8, width=2)
        surf.blit(glow, (x+7, y+7))

        pygame.draw.line(surf, (30, 255, 150), (x+16, y+10), (x+w-16, y+10), 1)
        pygame.draw.line(surf, (80, 190, 255), (x+16, y+h-12), (x+w-36, y+h-12), 1)

        notch = [(x+w-14, y+10), (x+w-6, y+18), (x+w-6, y+h-18), (x+w-14, y+h-10), (x+w-14, y+10)]
        pygame.draw.polygon(surf, (0, 170, 250), notch, width=2)

        offset_y = 2 if self._pressed else 0
        if self._pressed:
            shade = pygame.Surface((w, h), pygame.SRCALPHA)
            _rounded_rect(shade, (0, 0, 0, 120), shade.get_rect(), r)
            surf.blit(shade, (x, y))

        font = pygame.font.SysFont("serif", 30, bold=True)
        label = font.render(self.text, True, self.text_color)
        shadow = font.render(self.text, True, (0, 0, 0))
        lr = label.get_rect(center=(x + w // 2, y + h // 2 + offset_y))
        surf.blit(shadow, lr.move(0, 2))
        surf.blit(label, lr)

    def _draw_image_skin(self, surf):
        x, y, w, h = self.rect
        if not self._skin_img:
            pygame.draw.rect(surf, (30, 55, 90), self.rect, border_radius=10)
            pygame.draw.rect(surf, (200, 220, 240), self.rect, 2, border_radius=10)
        else:
            img = pygame.transform.smoothscale(self._skin_img, (w, h))
            surf.blit(img, (x, y))
        font = pygame.font.SysFont("serif", 30, bold=True)
        label = font.render(self.text, True, self.text_color)
        surf.blit(label, label.get_rect(center=self.rect.center))

    def draw(self, surface):
        if self.theme == "neon":
            self._draw_neon(surface)
        else:
            self._draw_image_skin(surface)

    def handle_event(self, event):
        if event.type == pygame.MOUSEMOTION:
            self._hover = self.rect.collidepoint(event.pos)
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.rect.collidepoint(event.pos):
                self._pressed = True
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            was_pressed = self._pressed
            self._pressed = False
            if was_pressed and self.rect.collidepoint(event.pos):
                return self.action
        return None

def draw_title_plain(surface, text, center_x, y, size=96, shadow_offset=(0, 5)):
    font = pygame.font.SysFont("serif", size, bold=True)

    shadow = font.render(text, True, (0, 0, 0))
    shadow_surf = pygame.Surface(shadow.get_size(), pygame.SRCALPHA)
    shadow_surf.blit(shadow, (0, 0))
    for dx, dy, a in ((0, 0, 120), (2, 2, 90), (-2, 2, 90), (2, -2, 90), (-2, -2, 90)):
        tmp = font.render(text, True, (0, 0, 0))
        tmp.set_alpha(a)
        shadow_surf.blit(tmp, (dx, dy))
    sr = shadow_surf.get_rect(midtop=(center_x + shadow_offset[0], y + shadow_offset[1]))
    surface.blit(shadow_surf, sr)

    outline_color = (220, 220, 230)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        o = font.render(text, True, outline_color)
        rect_o = o.get_rect(midtop=(center_x + dx, y + dy))
        surface.blit(o, rect_o)

    title = font.render(text, True, (255, 255, 255))
    rect = title.get_rect(midtop=(center_x, y))
    surface.blit(title, rect)
    return rect
