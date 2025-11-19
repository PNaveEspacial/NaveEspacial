# Reexporta utilidades de la cáscara imperativa
from .assets import cargar_imagen, cargar_fondo_cover, cargar_recursos
from .audio import play_sound, cargar_sonidos, iniciar_musica, parar_musica
from .records import cargar_records, guardar_record, top3
from .estilos_ui import Button, draw_text, draw_title_plain, draw_hearts
from .pantallas import (
    pedir_nombre, mostrar_menu, mostrar_instrucciones,
    mostrar_records, mostrar_pausa, mostrar_pantalla_game_over
)
from .renderizado import dibujar_escena, draw_boss_bar
from .bucle import ejecutar_juego
# Reexporta utilidades de la cáscara imperativa
from .assets import cargar_imagen, cargar_fondo_cover, cargar_recursos
from .audio import play_sound, cargar_sonidos, iniciar_musica, parar_musica
from .records import cargar_records, guardar_record, top3
from .estilos_ui import Button, draw_text, draw_title_plain, draw_hearts, set_heart_image
from .pantallas import (
    pedir_nombre, mostrar_menu, mostrar_instrucciones,
    mostrar_records, mostrar_pantalla_game_over, mostrar_pausa
)
from .renderizado import dibujar_escena, draw_boss_bar
from .bucle import ejecutar_juego