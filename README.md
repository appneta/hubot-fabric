# hubot-fabric

Execute Fabric tasks from Hubot.

[![Build Status](https://travis-ci.org/appneta/hubot-fabric.svg?branch=master)](https://travis-ci.org/appneta/hubot-fabric)

## Installation

In hubot project repo, run:

`npm install hubot-fabric --save`

Then add **hubot-fabric** to your `external-scripts.json`:

```json
["hubot-fabric"]
```

## Documentation

See [`src/fabric.coffee`](https://github.com/appneta/hubot-fabric/blob/master/src/fabric.coffee) for full documentation.

## Sample Interaction

```
user1>> hubot fabric -Hhost.example.com uptime
hubot>> exited: 0
[localhost] Executing task 'uptime'
[localhost] run: uptime
[localhost] out:  18:43:04 up 10 days, 10:51,  1 user,  load average: 0.04, 0.08, 0.09

Done.
Disconnecting from localhost... done.
```
