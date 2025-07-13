import { vi } from "vitest";

export const Player = vi.fn(function (options) {
  this.options = options;
  this.addListener = vi.fn().mockReturnThis();
  this.connect = vi.fn().mockReturnThis();
  this.disconnect = vi.fn().mockReturnThis();
  this.togglePlay = vi.fn().mockReturnThis();
  this.pause = vi.fn().mockReturnThis();
  this.resume = vi.fn().mockReturnThis();
  this.nextTrack = vi.fn().mockReturnThis();
  this.previousTrack = vi.fn().mockReturnThis();
  this.seek = vi.fn().mockReturnThis();
  this.getCurrentState = vi.fn().mockReturnThis();
  this.getVolume = vi.fn().mockReturnThis();
  this.setVolume = vi.fn().mockReturnThis();
  this.setName = vi.fn().mockReturnThis();
  this.activateElement = vi.fn().mockReturnThis();
  this.removeListener = vi.fn().mockReturnThis();
});

export default {
  Player,
};
