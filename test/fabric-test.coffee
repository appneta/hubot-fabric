chai = require 'chai'
sinon  = require 'sinon'
chai.use require 'sinon-chai'
expect = require('chai').expect
path   = require 'path'
child_process = require('child_process')

Robot       = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage

CONFIG = """
{
  "path": "/my/fab",
  "file": "/my/fabfile.py",
  "auth": "/my/ssh-key.pem",
  "user": "user",
  "pass": "pass",
  "tasks": [
    "df",
    "free"
  ],
  "prefix": "",
  "role": "fabric"
}
"""

describe 'fabric', ->
  robot = {}
  adminUser = {}
  roleUser = {}
  adapter = {}
  cp =
    exec: sinon.stub child_process, 'exec'
    spawn: sinon.stub child_process, 'spawn'

  beforeEach (done) ->
    # Fake environment variables
    process.env.HUBOT_AUTH_ADMIN = "1"
    process.env.HUBOT_FABRIC_CONFIG = CONFIG

    # Create new robot, without http, using mock adapter
    robot = new Robot null, "mock-adapter", false

    # Reset spies
    cp.exec.reset()
    cp.spawn.reset()

    robot.adapter.on "connected", ->
      # load modules and configure it for the robot. This is in place of
      # external-scripts
      require(path.resolve path.join("node_modules/hubot-auth/src"), "auth")(@robot)
      require('../src/fabric')(@robot)

      adminUser = robot.brain.userForId "1", {
        name: "admin-user"
        room: "#test"
      }

      roleUser = robot.brain.userForId "2", {
        name: "role-user"
        room: "#test"
        roles: [
          'fabric'
        ]
      }

      adapter = robot.adapter

    robot.run()

    done()

  afterEach ->
    robot.shutdown()

  it 'list fabric tasks', (done) ->
    adapter.on "send", (envelope, strings) ->
      expect(strings[0]).to.contain 'Authorized fabric tasks: df,free'
      done()

    adapter.receive(new TextMessage adminUser, "hubot fabric tasks")

  it 'exec df task', (done) ->
    adapter.receive(new TextMessage roleUser, "hubot fabric -Htest.example.com df")
    expect(cp.exec).to.be.calledOnce
    done()

  it 'explicit exec df task', (done) ->
    adapter.receive(new TextMessage roleUser, "hubot fabric exec -Htest.example.com df")
    expect(cp.exec).to.be.calledOnce
    done()

  it 'spawn df task', (done) ->
    adapter.receive(new TextMessage roleUser, "hubot fabric spawn -Htest.example.com df")
    expect(cp.spawn).to.be.calledOnce
    done()

  it 'exec df task without access', (done) ->
    adapter.on "send", (envelope, strings) ->
      expect(cp.exec).to.be.not.called
      expect(strings[0]).to.contain 'Access denied'
      done()

    adapter.receive(new TextMessage adminUser, "hubot fabric -Htest.example.com df")

  it 'attempt exec of invalid task', (done) ->
    adapter.on "send", (envelope, strings) ->
      expect(cp.exec).to.be.not.called
      expect(strings[0]).to.contain 'Unauthorized task'
      done()

    adapter.receive(new TextMessage adminUser, "hubot fabric -Htest.example.com foo")

  it 'hubot-auth module not installed', (done) ->
    robot.auth = null
    adapter.receive(new TextMessage adminUser, "hubot fabric -Htest.example.com df")
    expect(cp.exec).to.be.calledOnce
    done()
