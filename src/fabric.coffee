# Description
#   Execute Fabric tasks from Hubot.
#
# Configuration:
#   HUBOT_FABRIC_CONFIG
#
# Commands:
#   hubot fabric -Hhost.example.com my_task
#   hubot fabric exec -Hhost.example.com my_task:'arg1,arg2'
#   hubot fabric spawn -Hhost.example.com my_task
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
      msg.send formatOutput(stdout)
    if stderr?.length
      msg.send formatOutput(stderr)
    if error isnt null
      msg.send formatOutput(error)

  p.on 'exit', (code) ->
    console.log("exited: #{code}")

spawn = (robot, msg, cmd, args) ->
  p = child_process.spawn cmd, args

  p.stdout.on 'data', (data) ->
    msg.send formatOutput(data.toString())

  p.stderr.on 'data', (data) ->
    msg.send formatOutput(data.toString())

  p.on 'close', (code) ->
    msg.send formatOutput("exited: #{code}")

formatOutput = (text) ->
  if HUBOT_FABRIC_CONFIG.prefix?
    return HUBOT_FABRIC_CONFIG.prefix + text
  return text

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

isTaskValid = (task) ->
  result = task.split(':')
  return result[0] in HUBOT_FABRIC_CONFIG.tasks

executeTask = (robot, msg, method, task, host) ->
  if not isTaskValid(task)
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

  robot.respond /fabric (exec|spawn)? ?(-H) ?([\w.\-_]+) (.+)/i, (msg) ->
    method = msg.match[1] ||= 'exec'
    host = msg.match[2] + msg.match[3]
    task = msg.match[4]
    executeTask(robot, msg, method, task, host)

  robot.respond /fabric tasks/i, (msg) ->
    msg.send "Authorized fabric tasks: #{HUBOT_FABRIC_CONFIG.tasks}"
