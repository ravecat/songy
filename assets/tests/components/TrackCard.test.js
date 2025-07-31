import { render, screen } from "@testing-library/svelte";
import { expect, test, describe } from "vitest";
import TrackCard from "@components/TrackCard.svelte";

describe("TrackCard", () => {
  const mockTrack = {
    title: "Test Song",
    artist: "Test Artist",
    year: 2023,
  };

  test("renders track information correctly", () => {
    render(TrackCard, { props: { track: mockTrack } });

    expect(screen.getByText("Test Song")).toBeInTheDocument();
    expect(screen.getByText("Test Artist")).toBeInTheDocument();
    expect(screen.getByText("2023")).toBeInTheDocument();
  });
});
