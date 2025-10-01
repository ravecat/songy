import { Socket } from "phoenix";

const socket = new Socket("/socket", {
  params: {
    user_token: window.userToken,
  },
});

socket.connect();

export default socket;
