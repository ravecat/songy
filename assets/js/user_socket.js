import { Socket } from "phoenix";

const socket = new Socket("/socket", {
  params: { token: window.channelToken }
});

socket.connect();

export default socket;
