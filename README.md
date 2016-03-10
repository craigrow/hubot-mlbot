# hubot-mlbot

A hubot that knows what happened with your favorite MLB team 

See [`src/mlbot.coffee`](src/mlbot.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-mlbot --save`

Then add **hubot-mlbot** to your `external-scripts.json`:

```json
[
  "hubot-mlbot"
]
```

## Sample Interaction

```
mlbot> mlbot how bout those mariners
mlbot> The mariners won yesterday
San Diego 0 at Seattle 7
mlbot> mlbot how bout them sox
mlbot> The sox lost yesterday
Minnesota 7 at Boston 4
mlbot standings alw
mlbot>
American League West
=======================
Rangers          88-74
Astros   		 86-76
Angels   		 85-77
Mariners         76-86
Athletics        68-94
```
