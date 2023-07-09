%%raw(`import {Socket} from "phoenix"`)

type socket = Socket
type channel = Channel
type params = {token: string}
type chanParams = {}
type endPoint = string

let newSocket = (endPoint: endPoint, params: params) => {
  ignore(params)
  ignore(endPoint)
  %raw(`new Socket(endPoint, {params: params})`)
}

let connect = (socket: socket) => {
  ignore(socket)
  %raw(`socket.connect()`)
}

let newChannel = (socket: socket, topic: string, params: chanParams) => {
  ignore(params)
  ignore(topic)
  ignore(socket)
  %raw(`socket.channel(topic, params)`)
}

let joinChannel = (channel: channel) => {
  ignore(channel)
  %raw(`channel.join()`)
}

let on = (channel: channel, message: string, callback: 'a) => {
  ignore(callback)
  ignore(message)
  ignore(channel)
  %raw(`channel.on(message, callback)`)
}

let push = (channel: channel, message: string, payload: 'a) => {
  ignore(payload)
  ignore(message)
  ignore(channel)
  %raw(`channel.push(message, payload)`)
}
