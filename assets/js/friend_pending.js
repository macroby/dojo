import "../css/app.css"
import CancelInviteButton from "./cancel_invite"
import socket from "./friend_pending_socket"

let cancel_invite_button = new CancelInviteButton(document.getElementById('cancel_invite'));

var roomID = window.location.pathname;

let channel = socket.channel('room:' + roomID.replace('/', ''), {}); // connect to chess "room"
channel.join(); // join the channel.

channel.on('invite_accepted', function (payload) { // listen to the 'shout' event
    location.reload(); 
  });
