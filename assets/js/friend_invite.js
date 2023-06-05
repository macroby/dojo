import "../css/app.css"
import socket from "./friend_invite_socket"

var roomID = window.location.pathname;

let channel = socket.channel('home:' + roomID, {}); // connect to chess "room"
channel.join(); // join the channel.

channel.on('cancel', function (payload) { // listen to the 'shout' event
  location.reload(); 
});