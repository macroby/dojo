%%raw(`import {Socket} from "phoenix"`)

type socket = Socket
type channel = Channel
type params = {token: string}
type chanParams = {}
type endPoint = string

let newSocket = (endPoint: endPoint, params: params) => {
  %raw(`new Socket(endPoint, {params: params})`)
}

let connect = (socket: socket) => {
  %raw(`socket.connect()`)
}

let newChannel = (socket: socket, topic: string, params: chanParams) => {
  %raw(`socket.channel(topic, params)`)
}

let joinChannel = (channel: channel) => {
  %raw(`channel.join()`)
}

let on = (channel: channel, message: string, callback: 'a) => {
  %raw(`channel.on(message, callback)`)
}

let push = (channel: channel, message: string, payload: 'a) => {
  %raw(`channel.push(message, payload)`)
}