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
how bout those mariners
mlbot> The mariners are leading Houston in the Middle of inning 8: 2-3
what about yesterday
mlbot> mariners
They beat LA Angels yesterday!
how bout those sox
mlbot> The sox beat Atlanta today! 1-0
standings alw
mlbot> mlbot standings alw
mlbot>
American League West
=======================
Athletics        10-10
Rangers          10-10
Mariners         9-9
Angels   		 8-11
Astros   		 6-13
```
