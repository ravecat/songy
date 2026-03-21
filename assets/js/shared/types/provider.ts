export const Provider = {
  SPOTIFY: "spotify",
  APPLE: "apple",
  ITUNES: "itunes",
} as const;

export type Provider = (typeof Provider)[keyof typeof Provider];
