# Docker Compose で動く永続実行（durable execution）ラボ：ワークフローエンジン、PostgreSQL のステップジャーナル、リプレイ、冪等性キー、サガ

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml)

[MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning) の授業用ラボです。このプラットフォームでは、学校・カレッジ・大学が学生一人ひとりに、ブラウザーで使えるデータベース、コンテナ、ターミナルを用意できます。このラボは永続実行（durable execution）を基礎から教えます。長時間かかるジョブやワークフローが、クラッシュしても処理を失わずに続けられるしくみです。約100行の Python で書かれたワークフローエンジンが、終わったステップを PostgreSQL のジャーナル表に書き込み、クラッシュ後に再実行すると、その行をリプレイしてから先へ進みます。学生はワークフローをわざとクラッシュさせ、再開させます。素朴なジョブがカードに二重請求する様子、注文がジャーナルをリプレイする様子、冪等性キーで守られた請求、指数バックオフとジッター付きのリトライ、永続タイマー、サガとして予約する旅行を扱います。商用エンジン（Temporal、Restate、DBOS、AWS Lambda の durable functions）は動いていません。それらに共通する考え方を見せるラボです。[Durable execution](https://mitsurutech.co.uk/resources/university/durable-execution) モジュールで使うラボです。

`compose.yaml` という `docker-compose` ファイル1つでできていて、手元のマシンでもプラットフォームでも同じように動きます。プラットフォームでは、学生ごとにインターネットへ出られない専用のコピーが用意されます。

## プラットフォームで使う

プラットフォームでは、学生ごとにラボのコピーがブラウザーの中に作られ、横にターミナルが付きます。

**試すには：** [コンテナのページ](https://mitsurutech.co.uk/container)を開き、**Sample labs** でこのラボを探して Start を押します。無料アカウントが必要です。

**クラスの課題にするには：**

1. モジュールで種類 **Lab** のタスクを作り、**In a GitHub repository** を選びます。
2. `https://github.com/mitsurutech/lab-durable-lab` とブランチ `main` を指定します。compose ファイルは既定の `compose.yaml` です。変更したい場合は、先にリポジトリをフォークしてください。
3. 公開します。学生のコピーは公開したコミットから始まるので、あとでここが変わっても、配布済みのラボは変わりません。

詳しくはヘルプマニュアルの[このラボのページ](https://mitsurutech.co.uk/help/lab-durable-lab)と[コンテナラボのガイド](https://mitsurutech.co.uk/help/labs)をご覧ください。対応する基本レッスンは **Durable Execution Basics** です。学校のアカウントはまだですか？[最初の1年間は無料](https://mitsurutech.co.uk/pricing)で、学生50人まで使えます。[登録](https://mitsurutech.co.uk/signup)に必要なのはメールアドレスだけです。

## 中身

サービスは2つです。`db` は PostgreSQL で、ジャーナルとワークフローが書き込む表を持ちます。`worker` は Python で、`/tmp` に次のファイルがあります。どれもラボの起動時に compose ファイルが書き出します。

| ファイル | 内容 |
|---|---|
| `pg.py` | ラボのために書いたとても小さな PostgreSQL クライアント。標準の Python イメージにはデータベースドライバーがないためです |
| `engine.py` | エンジン本体。ステップは1回だけ実行され、結果はジャーナルに入り、再実行ではリプレイされます |
| `shop.py` | 外の世界。在庫、決済サービス、メール、配送、予約で、それぞれ1行を書き込みます |
| `naive.py` | ジャーナルのない注文処理。単純なリトライが何を繰り返すかを見ます |
| `order.py` | 永続ワークフローとしての注文。`--crash-after`、`--crash-inside`、`--keyed`、`--v2` が使えます |
| `retry.py` | 上限付きの指数バックオフと、固定シードのジッター |
| `remind.py` | `--now` で与える時計で動く永続タイマー |
| `saga.py` | サガとして予約する旅行。新しいものから順に補償します |

## 手元のマシンで動かす

Compose プラグイン付きの Docker が必要です。

```bash
docker compose up -d --wait
docker compose exec worker python3 order.py order-7 --fresh --crash-after 2
docker compose exec worker python3 order.py order-7
docker compose exec db psql -U durable -c "SELECT workflow, seq, step, result FROM journal"
```

1つ目のコマンドは2ステップを実行し、わざとクラッシュして止まります。2つ目はその2ステップをジャーナルからリプレイし、残りの2ステップを実行します。どの実行も毎回同じ内容を表示します。時計を読む処理はなく、唯一の乱数はシードが固定されています。ラボはポートを公開しません。ラボの外からは届かないので、データベースはパスワードを求めません。ほかの場所では PostgreSQL をこのように動かさないでください。削除は `docker compose down -v` です。

## ラボでできないこと

ラボはインターネットに出られないので、中に何かをインストールしたりダウンロードしたりはできません。**何も保存されません**。ラボを止めるとジャーナルも書いたファイルもすべて消えるので、提出するものは先にターミナルからコピーしてください。`compose.yaml` 冒頭のコメントに、このラボが何であり何でないかが書いてあります。

## ラボの検証

`test/check.sh` は、プラットフォームの実行環境がすべてのサービスを起動するのと同じ条件（すべての capability を外し、`no-new-privileges`、プロセス数の上限、メモリの上限、インターネットなし）でラボを起動します。そのうえで各ワークフローをクラッシュさせて再開し、表示内容とデータベースの中身を確かめます。Docker が必要で、push のたびに実行されます。上のバッジがその結果です。

```bash
test/check.sh
```

## ライセンス

この作品は [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.ja) で提供しています。Mitsuru Technologies Ltd の名前を表示し、営利目的で使わず、改変したものを同じライセンスで共有するなら、学習や授業のために共有・改変できます。全文は `LICENSE` ファイルにあります。PostgreSQL と Python は公式イメージを変更せずに使っており、それぞれのライセンスに従います。

## このラボについて

[Mitsuru Technologies](https://mitsurutech.co.uk) が [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning) のために作りました。学校やカレッジ向けに、Python、Java、Go、Node、SQL、Linux をブラウザーで使え、コンテナラボ、GitHub からデプロイする Web アプリ、自動採点のクイズもあります。アカウントなしでコードを試すなら [playground](https://mitsurutech.co.uk/playground) へどうぞ。
