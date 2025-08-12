import { render, screen } from "@testing-library/svelte";
import { expect, test, describe } from "vitest";
import TrackCard from "~components/TrackCard.svelte";

describe("TrackCard", () => {
  const mockTrack = {
    title: "Test Song",
    artist: "Test Artist",
    year: 2023,
  };

  test("renders track information correctly with default props", () => {
    render(TrackCard, { props: { track: mockTrack } });

    expect(screen.getByText("Test Song")).toBeInTheDocument();
    expect(screen.getByText("Test Artist")).toBeInTheDocument();
    expect(screen.getByText("2023")).toBeInTheDocument();
  });

  test("shows revealed card when revealed prop is true", () => {
    render(TrackCard, { props: { track: mockTrack, revealed: true } });

    expect(screen.getByText("Test Song")).toBeInTheDocument();
    expect(screen.getByText("Test Artist")).toBeInTheDocument();
    expect(screen.getByText("2023")).toBeInTheDocument();
    expect(screen.queryByText("?")).not.toBeInTheDocument();
  });
  
  test("shows hidden card when revealed prop is false", () => {
    render(TrackCard, { props: { track: mockTrack, revealed: false } });
    
    expect(screen.getByText("?")).toBeInTheDocument();
    expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
    expect(screen.queryByText("Test Artist")).not.toBeInTheDocument();
    expect(screen.queryByText("2023")).not.toBeInTheDocument();
  });
});
