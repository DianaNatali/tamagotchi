# Descripción de hardware de la pantalla LCD ILI9341:

## Consideraciones:

1. El desarrollo se realizó para ser implementado en la tarjeta Zybo Z720.
2. La tarjeta tiene un reloj de 125MHz.
3. La tarjeta no tiene lógica negada.
4. El archivo con extensión xdc corresponde a la definición del mapa de pines de la FPGA en la ```IDE Vivado```.


## ¿Cómo probar?

Después de hacer los cambios en la descripción de hardware necesarios de acuerdo a la plataforma en la que se desee implementar, también se debe realizar lo siguiente:


El archivo ```convert2pixels.py``` permite convertir la imagen deseada en un archivo txt con los valores en hexadecimal de cada pixel de la imagen, para ello se debe:

1. Convertir la imagen deseada a una resolución de 320x240 pixeles.
2. Instalar el paquete de OpenCV de Python con:

```pip install opencv-python```

3. En la línea 3, en el argumento de la función ```cv2.imread()```, pasar como parámetro el nombre del archivo, incluyendo la extensión del mismo.
4. Cambiar el nombre del archivo ```.txt``` por el nombre deseado, en la línea 15.
5. Una vez se ejecute el script, se generará en el directorio un archivo ```.txt``` con 76800 píxeles.
6. Se debe reemplazar, en la línea 25 del archivo ```ili9341_top```, el nombre del archivo generado en el paso anterior, incluyendo el directorio del mismo.