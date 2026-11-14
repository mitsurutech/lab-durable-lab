# Durable-Execution-Labor mit Docker Compose: eine Workflow-Engine, ein Schritt-Journal in PostgreSQL, Replay, Idempotenzschlüssel und Sagas

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml)

Ein fertiges Labor für den Unterricht, von der [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), auf der Schulen, Colleges und Hochschulen allen Studierenden eigene Datenbanken, Container und ein Terminal im Browser geben. Es erklärt Durable Execution von Grund auf: wie ein langer Job oder ein Workflow einen Absturz übersteht. Eine Workflow-Engine aus rund hundert Zeilen Python schreibt jeden fertigen Schritt in eine Journal-Tabelle in PostgreSQL, und ein Neustart nach einem Absturz spielt diese Zeilen erneut ab (Replay) und macht weiter. Sie lassen Workflows absichtlich abstürzen und setzen sie fort: ein einfacher Job, der eine Karte doppelt belastet, eine Bestellung, die ihr Journal abspielt, eine Abbuchung, die ein Idempotenzschlüssel schützt, Wiederholungen mit exponentiellem Backoff und Jitter, ein dauerhafter Timer und eine Reise, die als Saga gebucht wird. Keine kommerzielle Engine (Temporal, Restate, DBOS oder AWS Lambda Durable Functions) läuft darin; das Labor zeigt die Idee, die sie gemeinsam haben. Es ist das Labor zum Modul [Durable execution](https://mitsurutech.co.uk/resources/university/durable-execution).

Es besteht aus einer einzigen `docker-compose`-Datei, `compose.yaml`, und läuft auf Ihrem eigenen Rechner genauso wie auf der Plattform, wo alle Studierenden eine private Kopie ohne Weg ins Internet bekommen.

## Auf der Plattform verwenden

Die Plattform gibt allen Studierenden eine eigene Kopie eines Labors im Browser, mit einem Terminal daneben.

**Zum Ausprobieren:** Öffnen Sie die [Container-Seite](https://mitsurutech.co.uk/container), suchen Sie dieses Labor unter **Sample labs** und drücken Sie Start. Dafür ist ein kostenloses Konto nötig.

**Als Aufgabe für eine Klasse:**

1. Legen Sie in Ihrem Modul eine Aufgabe vom Typ **Lab** an und wählen Sie **In a GitHub repository**.
2. Geben Sie `https://github.com/mitsurutech/lab-durable-lab` mit dem Branch `main` an. Die Compose-Datei ist standardmäßig `compose.yaml`. Forken Sie das Repository zuerst, wenn Sie es ändern möchten.
3. Veröffentlichen Sie. Jede Kopie startet von dem veröffentlichten Commit, eine spätere Änderung hier verändert also kein bereits gestelltes Labor.

Die [Seite zu diesem Labor](https://mitsurutech.co.uk/help/lab-durable-lab) im Handbuch und der [Leitfaden zu Container-Laboren](https://mitsurutech.co.uk/help/labs) erklären den Rest. Die passende Grundlagenlektion heißt **Durable Execution Basics**. Noch kein Konto für Ihre Einrichtung? [Das erste Jahr ist kostenlos](https://mitsurutech.co.uk/pricing) für bis zu 50 Studierende, und [die Anmeldung](https://mitsurutech.co.uk/signup) braucht nur eine E-Mail-Adresse.

## Was darin ist

Zwei Dienste. `db` ist PostgreSQL und hält das Journal und die Tabellen, in die die Workflows schreiben. `worker` ist Python mit diesen Dateien in `/tmp`, die die Compose-Datei beim Start alle selbst schreibt:

| Datei | Was sie ist |
|---|---|
| `pg.py` | Ein sehr kleiner PostgreSQL-Client, für das Labor geschrieben, weil kein Standard-Python-Image einen Datenbanktreiber enthält |
| `engine.py` | Die Engine: Ein Schritt läuft einmal, sein Ergebnis kommt ins Journal, ein Neustart spielt es ab |
| `shop.py` | Die Außenwelt: Lager, Zahlungsanbieter, E-Mail, Kurier und Buchungen, jeweils mit einer Zeile in der Datenbank |
| `naive.py` | Die Bestellung ohne Journal, um zu sehen, was ein einfacher Neustart wiederholt |
| `order.py` | Die Bestellung als dauerhafter Workflow, mit `--crash-after`, `--crash-inside`, `--keyed` und `--v2` |
| `retry.py` | Backoff mit Obergrenze und Jitter aus einem festen Seed |
| `remind.py` | Ein dauerhafter Timer mit einer Uhr, die Sie mit `--now` angeben |
| `saga.py` | Eine Reise als Saga gebucht, kompensiert vom neuesten Schritt an |

## Auf dem eigenen Rechner starten

Sie brauchen Docker mit dem Compose-Plugin.

```bash
docker compose up -d --wait
docker compose exec worker python3 order.py order-7 --fresh --crash-after 2
docker compose exec worker python3 order.py order-7
docker compose exec db psql -U durable -c "SELECT workflow, seq, step, result FROM journal"
```

Der erste Befehl führt zwei Schritte aus und hält mit einem absichtlichen Absturz an. Der zweite spielt diese zwei Schritte aus dem Journal ab und führt die anderen zwei aus. Jeder Lauf gibt jedes Mal dasselbe aus: Nichts liest die Uhr, und der einzige Zufall hat einen festen Seed. Das Labor veröffentlicht keinen Port. Die Datenbank fragt nach keinem Passwort, weil nichts außerhalb des Labors sie erreicht; betreiben Sie PostgreSQL nirgendwo sonst so. Entfernen Sie es mit `docker compose down -v`.

## Was in einem Labor nicht geht

Das Labor hat keinen Weg ins Internet, darin lässt sich also nichts installieren oder herunterladen. **Nichts wird gespeichert**: Wer das Labor stoppt, verliert das Journal und alle geschriebenen Dateien, kopieren Sie also vorher aus dem Terminal, was Sie abgeben. Der Kommentar am Anfang von `compose.yaml` sagt, was das Labor ist und was nicht.

## Das Labor prüfen

`test/check.sh` startet das Labor so, wie der Runner der Plattform jeden Dienst startet (alle Capabilities entfernt, `no-new-privileges`, ein Prozesslimit, Speicherlimits und kein Weg ins Internet). Dann lässt es jeden Workflow abstürzen, setzt ihn fort und prüft, was er ausgibt und was in der Datenbank steht. Es braucht Docker und läuft bei jedem Push; das ist das Abzeichen oben.

```bash
test/check.sh
```

## Lizenz

Dieses Werk steht unter der Lizenz [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.de). Sie dürfen es zum Lernen und Lehren teilen und bearbeiten, wenn Sie Mitsuru Technologies Ltd nennen, es nicht kommerziell nutzen und Bearbeitungen unter derselben Lizenz weitergeben. Der vollständige Text steht in der Datei `LICENSE`. PostgreSQL und Python laufen unverändert aus ihren offiziellen Images, unter ihren eigenen Lizenzen.

## Über uns

Von [Mitsuru Technologies](https://mitsurutech.co.uk) für die [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning): Python, Java, Go, Node, SQL und Linux im Browser für Schulen und Colleges, mit Container-Laboren, Web-Apps aus GitHub und Quizzen, die sich selbst korrigieren. Code ohne Konto ausprobieren können Sie im [Playground](https://mitsurutech.co.uk/playground).
