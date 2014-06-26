chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'fabric', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    process.env.HUBOT_FABRIC_CONFIG = '{}'

    require('../src/fabric')(@robot)

  it 'registers a execute tasks listener', ->
    expect(@robot.respond).to.have.been.calledWith(/fabric (exec|spawn)? ?(-H) ?([\w.\-_]+) (.+)/i)

  it 'registers a list tasks listener', ->
    expect(@robot.respond).to.have.been.calledWith(/fabric tasks/i)
