import { Socket } from "phoenix";

const socket = new Socket("/socket", {
  params: { 
    user_token: window.userToken,
    provider_token: window.providerToken 
  }
});

socket.connect();

export default socket;
