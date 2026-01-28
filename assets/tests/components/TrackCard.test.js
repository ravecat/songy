import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, vi } from "vitest";
import TrackCard from "~components/TrackCard.svelte";

describe("Track card", () => {
  const mockTrack = {
    title: "Test Song",
    artist: "Test Artist",
    year: 2023,
  };

  describe("information", () => {
    test("shows when track is revealed", () => {
      render(TrackCard, { props: { track: mockTrack, revealed: true } });

      expect(screen.getByText("Test Song")).toBeInTheDocument();
      expect(screen.getByText("Test Artist")).toBeInTheDocument();
      expect(screen.getByText("2023")).toBeInTheDocument();
    });

    test("shows by default", () => {
      render(TrackCard, { props: { track: mockTrack } });

      expect(screen.getByText("Test Song")).toBeInTheDocument();
      expect(screen.getByText("Test Artist")).toBeInTheDocument();
      expect(screen.getByText("2023")).toBeInTheDocument();
    });

    test("hides when track is not revealed", () => {
      render(TrackCard, { props: { track: mockTrack, revealed: false } });

      expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
      expect(screen.queryByText("Test Artist")).not.toBeInTheDocument();
      expect(screen.queryByText("2023")).not.toBeInTheDocument();
    });
  });

  describe("back snippet", () => {
    test("renders custom back content when not revealed", () => {
      const { container } = render(TrackCard, {
        props: { track: mockTrack, revealed: false },
      });

      // Без snippet обратная сторона пуста
      const backElement = container.querySelector('.track-card__back');
      expect(backElement).toBeInTheDocument();
      expect(backElement).toBeEmptyDOMElement();
    });

    test("hides back content when revealed", () => {
      const { container } = render(TrackCard, {
        props: { track: mockTrack, revealed: true },
      });

      const backElement = container.querySelector('.track-card__back');
      expect(backElement.getAttribute('aria-hidden')).toBe('true');
    });
  });
});
