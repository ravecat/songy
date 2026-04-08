import type { Track } from "~contracts";

export const tracks = {
  current: {
    id: "track-current",
    title: "Current Track",
    artist: "Current Artist",
    year: 2024,
    cover_url: "https://example.com/current-cover.jpg",
    meta: {
      preview_url: "https://example.com/current-preview.mp3",
    },
  },
  timelineOne: {
    id: "timeline-1",
    title: "Timeline Track 1",
    artist: "Artist 1",
    year: 2020,
    cover_url: null,
    meta: {},
  },
  timelineTwo: {
    id: "timeline-2",
    title: "Timeline Track 2",
    artist: "Artist 2",
    year: 2021,
    cover_url: null,
    meta: {},
  },
  result: {
    id: "track-result",
    title: "Bohemian Rhapsody",
    artist: "Queen",
    year: 1975,
    cover_url: "https://example.com/cover.jpg",
    meta: {
      preview_url: "https://example.com/preview.mp3",
    },
  },
  media: {
    id: "1440783454",
    title: "Firestarter",
    artist: "The Prodigy",
    year: 1996,
    cover_url: null,
    meta: {
      preview_url: "https://audio-ssl.itunes.apple.com/preview.m4a",
    },
  },
} satisfies Record<string, Track>;
