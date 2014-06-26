# Description
#   Execute Fabric tasks from Hubot.
#
# Configuration:
#   HUBOT_FABRIC_CONFIG
#
# Commands:
#   hubot fabric my_task -Hhost.example.com
#   hubot fabric (exec|spawn) my_task -Hhost.example.com
#
# Notes:
#   None
#
# Author:
#   danriti

child_process = require('child_process')

HUBOT_FABRIC_CONFIG = JSON.parse process.env.HUBOT_FABRIC_CONFIG

exec = (robot, msg, cmd) ->
  p = child_process.exec cmd, (error, stdout, stderr) ->
    if stdout?.length
      msg.send stdout
    if stderr?.length
      msg.send stderr
    if error isnt null
      msg.send error

  p.on 'exit', (code) ->
    console.log("exited: #{code}")

spawn = (robot, msg, cmd, args) ->
  p = child_process.spawn cmd, args

  p.stdout.on 'data', (data) ->
    msg.send data.toString()

  p.stderr.on 'data', (data) ->
    msg.send data.toString()

  p.on 'close', (code) ->
    msg.send "exited: #{code}"

buildArgs = (task, host) ->
  c = HUBOT_FABRIC_CONFIG
  args = []

  args.push "-i#{c.auth}" if c.auth?
  args.push "-f#{c.file}" if c.file?
  args.push "#{host}"
  args.push "-u#{c.user}" if c.user?
  args.push "-p#{c.pass}" if c.pass?
  args.push task

  return args

buildCmd = (task, host) ->
  c = HUBOT_FABRIC_CONFIG

  cmd = "#{c.path}"
  cmd += " -i#{c.auth}" if c.auth?
  cmd += " -f#{c.file}" if c.file?
  cmd += " #{host}"
  cmd += " -u#{c.user}" if c.user?
  cmd += " -p#{c.pass}" if c.pass?
  cmd += " #{task}"

  return cmd

executeTask = (robot, msg, method, task, host) ->
  if task not in HUBOT_FABRIC_CONFIG.tasks
    msg.send "Unauthorized task: #{task}"
    return

  if method is 'exec'
    cmd = buildCmd(task, host)
    exec(robot, msg, cmd)
  else if method is 'spawn'
    cmd = HUBOT_FABRIC_CONFIG.path
    args = buildArgs(task, host)
    spawn(robot, msg, cmd, args)

module.exports = (robot) ->

  robot.respond /fabric (exec|spawn)? ?(.+) (-H)(.+)?/i, (msg) ->
    method = msg.match[1] ||= 'exec'
    task = msg.match[2]
    host = msg.match[3] + msg.match[4]
    executeTask(robot, msg, method, task, host)

  robot.respond /fabric tasks/i, (msg) ->
    msg.send "Authorized fabric tasks: #{HUBOT_FABRIC_CONFIG.tasks}"
