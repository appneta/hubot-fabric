# Description
#   Execute Fabric tasks from Hubot
#
# Configuration:
#   HUBOT_FABRIC_CONFIG
#
# Commands:
#   hubot fabric -Hhost.example.com uptime - execute the uptime fabric task on host.example.com
#   hubot fabric exec -Hhost.example.com uptime:'arg1,arg2' - execute the uptime fabric task with 2 arguments on host.example.com
#   hubot fabric spawn -Hhost.example.com uptime - asynchronously execute the uptime fabric task on host.example.com
#   hubot fabric tasks - list fabric tasks that are executable
#
# Notes:
#   HUBOT_FABRIC_CONFIG expects a JSON object structured like this:
#
#   {
#     "path": "/my/virtualenv/bin/fab",
#     "file": "/full/path/to/my/fabfile.py",
#     "auth": "/full/path/to/my/ssh-key.pem",
#     "user": "user",
#     "pass": "pass",
#     "tasks": [
#       "df",
#       "free",
#       "w",
#       "uptime",
#       "top"
#     ],
#     "prefix": "",
#     "role": "fabric"
#   }
#
#   - "path" (String) Path to the fabric executable script
#   - "file" (String) Path to the fabric file
#   - "auth" (String) Path to the SSH private key file
#   - "user" (String) (Optional) User name to use when connecting to remote hosts
#   - "pass" (String) (Optional) Password to use when connection to remote hosts
#   - "tasks" (Array) Strings of fabric tasks that can be executed. Set to ["*"]
#     if you do not wish to limit which tasks can be executed.
#   - "prefix" (String) (Optional) Used to format fabric's output using a message
#     formatter that is compatible with your Hubot adapter.
#
#     For instance, HipChat supports "/quote " to display messages in a fixed-width
#     format. Thus, you can set "prefix": "/quote " to apply this formatter to
#     fabric's output.
#   - "role" (String) (Optional) Uses the [auth.coffee][1] module for restricting
#     access via user configurable roles.
#
#     You can set "role" to "*" if you don't care about restricting access.
#
#   [1]: https://github.com/github/hubot/blob/master/src/scripts/auth.coffee
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
  if '*' in HUBOT_FABRIC_CONFIG.tasks
    return true
  result = task.split(':')
  return result[0] in HUBOT_FABRIC_CONFIG.tasks

userHasRole = (user, role, robot) ->
  if role is '*'
    return true

  return robot.auth.hasRole(user, role)

executeTask = (robot, msg, method, task, host) ->
  if not isTaskValid(task)
    msg.send "Unauthorized task: #{task}"
    return

  user = msg.message.user
  role = HUBOT_FABRIC_CONFIG.role

  if not userHasRole(user, role, robot)
    msg.send "Access denied. You must have this role to use this command: #{role}"
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
