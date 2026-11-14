# Durable execution lab with Docker Compose: a workflow engine, a step journal in PostgreSQL, replay, idempotency keys and sagas

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml)

A ready-made lab for classrooms, from the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), where schools, colleges and universities give every student their own databases, containers and terminal in the browser. It teaches durable execution from first principles: how a long-running job or workflow survives a crash. A workflow engine of about a hundred lines of Python writes each finished step to a journal table in PostgreSQL, and a rerun after a crash replays those rows and carries on. Students crash workflows on purpose and resume them: a plain job that charges a card twice, an order that replays its journal, a charge made safe by an idempotency key, retries with backoff and jitter, a durable timer and a trip booked as a saga. No commercial engine (Temporal, Restate, DBOS or AWS Lambda durable functions) runs in it; it shows the idea they share. It is the lab behind the [Durable execution](https://mitsurutech.co.uk/resources/university/durable-execution) module.

It is one `docker-compose` file, `compose.yaml`, and it runs the same on your own machine as it does on the platform, where every student gets a private copy with no way out to the internet.

## Using it on the platform

The platform gives every student their own copy of a lab, in the browser, with a terminal beside it.

**To try it:** open the [container page](https://mitsurutech.co.uk/container), find this lab in **Sample labs** and press Start. It needs a free account.

**To set it as work for a class:**

1. In your module, make a task of type **Lab** and choose **In a GitHub repository**.
2. Give `https://github.com/mitsurutech/lab-durable-lab` with the branch `main`. The compose file is the default, `compose.yaml`. Fork the repository first if you want to change it.
3. Publish. Every student's copy starts from the commit you published, so a later change here does not alter a lab already set.

The help manual's [page for this lab](https://mitsurutech.co.uk/help/lab-durable-lab) and its [guide to container labs](https://mitsurutech.co.uk/help/labs) cover the rest. The matching basic lesson is **Durable Execution Basics**. No college account yet? [Your first year is free](https://mitsurutech.co.uk/pricing) for up to 50 students, and [signing up](https://mitsurutech.co.uk/signup) takes an email address.

## What is in it

Two services. `db` is PostgreSQL, holding the journal and the tables the workflows write to. `worker` is Python, with these files in `/tmp`, all written by the compose file when the lab starts:

| File | What it is |
|---|---|
| `pg.py` | A very small PostgreSQL client, written for the lab, because no database driver is in a stock Python image |
| `engine.py` | The engine: a step runs once, its result goes in the journal, a rerun replays it |
| `shop.py` | The outside world: stock, a card provider, email, a courier and bookings, each writing a row |
| `naive.py` | The order job with no journal, to see what a plain retry repeats |
| `order.py` | The order as a durable workflow, with `--crash-after`, `--crash-inside`, `--keyed` and `--v2` |
| `retry.py` | Backoff with a cap and jitter from a fixed seed |
| `remind.py` | A durable timer on a clock you give with `--now` |
| `saga.py` | A trip booked as a saga, compensated newest first |

## Running it on your own machine

You need Docker with the Compose plugin.

```bash
docker compose up -d --wait
docker compose exec worker python3 order.py order-7 --fresh --crash-after 2
docker compose exec worker python3 order.py order-7
docker compose exec db psql -U durable -c "SELECT workflow, seq, step, result FROM journal"
```

The first command runs two steps and stops with a crash on purpose. The second replays those two steps from the journal and runs the other two. Every run prints the same every time: nothing reads the clock and the one random choice has a fixed seed. The lab publishes no port. The database asks for no password because nothing outside the lab can reach it, so never run PostgreSQL like this anywhere else. Remove it with `docker compose down -v`.

## What does not work in a lab

The lab has no way out to the internet, so nothing can be installed or downloaded into it. **Nothing is saved**: stopping the lab forgets the journal and every file you wrote, so copy what you hand in from the terminal first. The comment at the top of `compose.yaml` says what the lab is and what it is not.

## Checking the lab

`test/check.sh` starts the lab the way the platform's runner starts every service (all capabilities dropped, `no-new-privileges`, a process limit, memory limits, and no way out to the internet), then crashes and resumes each workflow and checks what it prints and what the database holds. It needs Docker and runs on every push, which is the badge at the top.

```bash
test/check.sh
```

## Licence

This work is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). You may share it and adapt it for learning and teaching, if you credit Mitsuru Technologies Ltd, do not use it commercially, and share anything you make from it under the same licence. The full text is in the `LICENSE` file. PostgreSQL and Python run unmodified from their official images under their own licences.

## About

Made by [Mitsuru Technologies](https://mitsurutech.co.uk) for the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning): Python, Java, Go, Node, SQL and Linux in the browser for schools and colleges, with container labs, web apps deployed from GitHub, and quizzes that mark themselves. Try code with no account in the [playground](https://mitsurutech.co.uk/playground).
