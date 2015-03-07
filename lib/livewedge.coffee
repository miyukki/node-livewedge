"use strict"

net = require "net"
dgram = require "dgram"

class LiveWedge
  DEBUG = false

  TCP_PORT = 8888
  UDP_PORT = 8888

  UDP_CONNECT_COMMAND = new Buffer [0x21, 0x00, 0x00, 0x00]

  @TransitionType =
    Cut : 0x00
    Mix : 0x01
    Dip : 0x02
    Wipe: 0x03

  @KeyType =
    Chroma: 0x00
    PinP  : 0x01

  constructor: ->
    @state = {}
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
    console.log "[TCP:LVW]", bytes if DEBUG
    @_parseCommand(bytes)

  _receiveUdpPacket: (bytes, remote) =>
    console.log "[UDP:LVW]", bytes if DEBUG
    @_parseCommand(bytes)

  _parseCommand: (bytes) ->
    type = bytes[2] << 16 | bytes[1] << 8 | bytes[0]
    data = bytes[4..]
    switch type
      when 0x6e
        @state.previewInput = data[0] + 1
      when 0x73
        # if data[8] == 0x01 # complete
        @state.programInput = data[8]

  getState: ->
    @state

  requestLocalDeviceList: (callback) ->

  changePreviewInput: (input) ->
    @_sendTcpPacket([0x08, 0x00, 0x00, 0x00])
    @_sendTcpPacket([0x10, 0x00, 0x00, 0x00,
                    input-1, 0x00, 0x00, 0x00])

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

  fadeToBlack: (time = 1000) ->
    @autoTransition(0, time)

  autoCutIn: (input) ->
    @autoTransition(input, 0, LiveWedge.TransitionType.Cut)

  autoKeyerTransition: (input, time = 1000, type = LiveWedge.TransitionType.Mix, dip_input = 0) ->
    @_sendTcpPacket([0x18, 0x00, 0x00, 0x00])
    @_sendTcpPacket([0x1c, 0x00, 0x00, 0x00,
                     0x2d, 0xef, 0x5c, 0xc6,
                     time & 0xff, time >> 8 & 0xff, 0x00, 0x00,
                     0x01, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,
                    input, type, dip_input, 0x00])

  autoKeyerFadeIn: (input, time = 1000) ->
    @autoKeyerTransition(input, time)

  autoKeyerFadeOut: (time) ->
    @autoKeyerTransition(0, time)

  changeKeyerType: (type) ->
    @_sendTcpPacket([0x08, 0x00, 0x00, 0x00])
    @_sendTcpPacket([0x40, 0x00, 0x00, 0x00,
                     type, 0x00, 0x00, 0x00])

module.exports = LiveWedge
