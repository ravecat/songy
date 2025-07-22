import { render, screen } from "@testing-library/svelte";
import { describe, it, expect } from "vitest";
import TrackCard from "@components/TrackCard.svelte";

describe("TrackCard", () => {
  const trackData = {
    artist: "The Beatles",
    album: "Abbey Road",
    title: "Come Together",
    year: "1969",
  };

  it("should display all track information", () => {
    render(TrackCard, { track: trackData });

    expect(screen.getByText("The Beatles")).toBeInTheDocument();
    expect(screen.getByText("1969")).toBeInTheDocument();
    expect(screen.getByText("Come Together")).toBeInTheDocument();
  });
});
