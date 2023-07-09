import {Socket} from "phoenix"

let socket = new Socket("/room_socket", {params: {token: user_token}})
socket.connect()

export default socket