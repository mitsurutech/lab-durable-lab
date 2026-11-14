# Laboratorio de ejecución duradera con Docker Compose: un motor de workflows, un diario de pasos en PostgreSQL, reproducción, claves de idempotencia y sagas

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml)

Un laboratorio listo para clase, de la [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), donde colegios, institutos y universidades dan a cada estudiante sus propias bases de datos, contenedores y terminal en el navegador. Enseña la ejecución duradera (*durable execution*) desde cero: cómo un proceso largo o un workflow sobrevive a una caída. Un motor de workflows de unas cien líneas de Python apunta cada paso terminado en una tabla de diario en PostgreSQL, y al relanzarlo tras una caída reproduce esas filas y sigue. Tumbas workflows a propósito y los reanudas: un trabajo ingenuo que cobra dos veces una tarjeta, un pedido que reproduce su diario, un cobro protegido con una clave de idempotencia, reintentos con espera exponencial y jitter, un temporizador duradero y un viaje reservado como saga. No corre ningún motor comercial (Temporal, Restate, DBOS ni las funciones duraderas de AWS Lambda): el laboratorio muestra la idea que comparten. Es el laboratorio del módulo [Durable execution](https://mitsurutech.co.uk/resources/university/durable-execution).

Es un único fichero `docker-compose`, `compose.yaml`, y funciona igual en tu máquina que en la plataforma, donde cada estudiante recibe una copia privada sin salida a internet.

## Usarlo en la plataforma

La plataforma da a cada estudiante su propia copia de un laboratorio, en el navegador, con un terminal al lado.

**Para probarlo:** abre la [página de contenedores](https://mitsurutech.co.uk/container), busca este laboratorio en **Sample labs** y pulsa Start. Necesitas una cuenta gratuita.

**Para ponerlo como tarea a una clase:**

1. En tu módulo, crea una tarea de tipo **Lab** y elige **In a GitHub repository**.
2. Indica `https://github.com/mitsurutech/lab-durable-lab` con la rama `main`. El fichero compose por defecto es `compose.yaml`. Haz antes un fork del repositorio si quieres cambiarlo.
3. Publica. La copia de cada estudiante parte del commit publicado, así que un cambio posterior aquí no altera un laboratorio ya asignado.

La [página de este laboratorio](https://mitsurutech.co.uk/help/lab-durable-lab) en el manual y su [guía de laboratorios en contenedor](https://mitsurutech.co.uk/help/labs) explican el resto. La lección básica que lo acompaña es **Durable Execution Basics**. ¿Aún no tienes cuenta de centro? [El primer año es gratis](https://mitsurutech.co.uk/pricing) hasta 50 estudiantes, y [registrarse](https://mitsurutech.co.uk/signup) solo pide un correo electrónico.

## Qué contiene

Dos servicios. `db` es PostgreSQL y guarda el diario y las tablas donde escriben los workflows. `worker` es Python, con estos ficheros en `/tmp`, todos escritos por el fichero compose al arrancar:

| Fichero | Qué es |
|---|---|
| `pg.py` | Un cliente de PostgreSQL muy pequeño, escrito para el laboratorio, porque ninguna imagen estándar de Python trae controlador de base de datos |
| `engine.py` | El motor: un paso se ejecuta una vez, su resultado va al diario y al relanzar se reproduce |
| `shop.py` | El mundo exterior: stock, pasarela de pago, correo, mensajería y reservas, cada uno escribe una fila |
| `naive.py` | El pedido sin diario, para ver qué repite un reintento sin más |
| `order.py` | El pedido como workflow duradero, con `--crash-after`, `--crash-inside`, `--keyed` y `--v2` |
| `retry.py` | Espera exponencial con tope y jitter de una semilla fija |
| `remind.py` | Un temporizador duradero con un reloj que das con `--now` |
| `saga.py` | Un viaje reservado como saga, compensado del más reciente al más antiguo |

## Ejecutarlo en tu máquina

Necesitas Docker con el plugin Compose.

```bash
docker compose up -d --wait
docker compose exec worker python3 order.py order-7 --fresh --crash-after 2
docker compose exec worker python3 order.py order-7
docker compose exec db psql -U durable -c "SELECT workflow, seq, step, result FROM journal"
```

La primera orden ejecuta dos pasos y se detiene con una caída a propósito. La segunda reproduce esos dos pasos desde el diario y ejecuta los otros dos. Cada ejecución imprime siempre lo mismo: nada lee el reloj y el único sorteo tiene una semilla fija. El laboratorio no publica ningún puerto. La base de datos no pide contraseña porque nada fuera del laboratorio puede llegar a ella, así que nunca ejecutes PostgreSQL así en otro sitio. Bórralo con `docker compose down -v`.

## Qué no funciona en un laboratorio

El laboratorio no tiene salida a internet, así que no se puede instalar ni descargar nada dentro. **No se guarda nada**: al parar el laboratorio se pierden el diario y todos los ficheros que escribiste, así que copia antes desde el terminal lo que vayas a entregar. El comentario al principio de `compose.yaml` explica qué es el laboratorio y qué no es.

## Comprobar el laboratorio

`test/check.sh` arranca el laboratorio como el ejecutor de la plataforma arranca cada servicio (sin ninguna capability, `no-new-privileges`, un límite de procesos, límites de memoria y sin salida a internet); después tumba y reanuda cada workflow y comprueba lo que imprime y lo que guarda la base de datos. Necesita Docker y se ejecuta en cada push: es la insignia de arriba.

```bash
test/check.sh
```

## Licencia

Esta obra está bajo licencia [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es). Puedes compartirla y adaptarla para aprender y enseñar si citas a Mitsuru Technologies Ltd, no la usas con fines comerciales y compartes lo que hagas a partir de ella con la misma licencia. El texto completo está en el fichero `LICENSE`. PostgreSQL y Python se ejecutan sin cambios desde sus imágenes oficiales, con sus propias licencias.

## Acerca de

Hecho por [Mitsuru Technologies](https://mitsurutech.co.uk) para la [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning): Python, Java, Go, Node, SQL y Linux en el navegador para colegios e institutos, con laboratorios en contenedor, aplicaciones web desplegadas desde GitHub y cuestionarios que se corrigen solos. Prueba código sin cuenta en el [playground](https://mitsurutech.co.uk/playground).
