"use strict"

net = require "net"
dgram = require "dgram"

class LiveWedge
  DEBUG = true

  TCP_PORT = 8888
  UDP_PORT = 8888

  UDP_CONNECT_COMMAND = new Buffer [0x21, 0x00, 0x00, 0x00]

  constructor: ->
    @udp = dgram.createSocket "udp4"
    @tcp = new net.Socket

  connect: (@address) ->
    @tcp.connect TCP_PORT, address, =>
      @udp.send UDP_CONNECT_COMMAND, 0, UDP_CONNECT_COMMAND.length, UDP_PORT, @address
      @udp.on 'message', @_receiveUdpPacket
      # setInterval @_ping 1000
    @tcp.on "data", @_receiveTcpPacket

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

module.exports = LiveWedge
