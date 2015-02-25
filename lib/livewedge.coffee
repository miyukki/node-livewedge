"use strict"

net = require "net"
dgram = require "dgram"

class LiveWedge
  DEBUG = true

  TCP_PORT = 8888
  UDP_PORT = 8888

  UDP_CONNECT_COMMAND = new Buffer [0x21, 0x00, 0x00, 0x00]

  @TransitionType =
    Cut : 0x00
    Mix : 0x01
    Dip : 0x02
    Wipe: 0x03

  constructor: ->
    @udp = dgram.createSocket "udp4"
    @tcp = new net.Socket

  connect: (@address) ->
    @tcp.connect TCP_PORT, address, =>
      @udp.send UDP_CONNECT_COMMAND, 0, UDP_CONNECT_COMMAND.length, UDP_PORT, @address
      @udp.on 'message', @_receiveUdpPacket
      setInterval @_ping, 1000
    @tcp.on "data", @_receiveTcpPacket

  _ping: =>
    @tcp.write new Buffer [0x04, 0, 0, 0]
    @tcp.write new Buffer [0x23, 0, 0, 0]

  _sendTcpPacket: (bytes) ->
    buffer = new Buffer bytes
    @tcp.write buffer

  _sendUdpPacket: (bytes) ->
    buffer = new Buffer bytes
    @udp.send buffer, 0, buffer.length, UDP_PORT, @address

  _receiveTcpPacket: (bytes) =>
    console.log "[TCP:LVW]", bytes

  _receiveUdpPacket: (bytes, remote) =>
    console.log "[UDP:LVW]", bytes

  requestLocalDeviceList: (callback) ->

  changeProgramInput: (input) ->
    @_sendUdpPacket([0x1b, 0x00, 0x00, 0x00, 0x2d, 0xef, 0x5c, 0xc6, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, input, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
  # setProgram
  # setProgramPinP: (border_color, border_width, border_r, border_g)

  autoTransition: (input, time = 1000, type = LiveWedge.TransitionType.Mix, dip_input = 0) ->
    @_sendTcpPacket([0x18, 0x00, 0x00, 0x00])
    @_sendTcpPacket([0x1c, 0x00, 0x00, 0x00,
                     0x2d, 0xef, 0x5c, 0xc6,
                     time & 0xff, time >> 8 & 0xff, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,
                    input, type, dip_input, 0x00,
                     0x00, 0x00, 0x00, 0x00])

  autoFadeIn: (input, time = 1000) ->
    @autoTransition(input, time)

  autoFadeOut: (input, time = 1000) ->
    @autoTransition(0, time)

  autoKeyerTransition: (input, time = 1000, type = LiveWedge.TransitionType.Mix) ->
    @_sendTcpPacket([0x18, 0x00, 0x00, 0x00])
    @_sendTcpPacket([0x1c, 0x00, 0x00, 0x00,
                     0x2d, 0xef, 0x5c, 0xc6,
                     time & 0xff, time >> 8 & 0xff, 0x00, 0x00,
                     0x01, 0x00, 0x00, 0x00,
                     0x00, type, 0x00, 0x00,
                    input, 0x01, 0x00, 0x00])

  autoKeyerFadeIn: (input, time = 1000) ->
    @autoKeyerTransition(input, time)

  autoKeyerFadeOut: (time) ->
    @autoKeyerTransition(0, time)

  # changeTransitionPosition: () ->
  # changeKeyerTransitionPosition: () ->

module.exports = LiveWedge
