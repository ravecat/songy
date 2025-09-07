import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, vi } from "vitest";
import TrackCard from "~components/TrackCard.svelte";

describe("Track card", () => {
  const mockTrack = {
    title: "Test Song",
    artist: "Test Artist",
    year: 2023,
  };

  const mockUser = {
    name: "Test User",
    avatar_url: "https://example.com/avatar.jpg",
  };

  describe("information", () => {
    test("shows when track is revealed", () => {
      render(TrackCard, { props: { track: mockTrack, revealed: true } });

      expect(screen.getByText("Test Song")).toBeInTheDocument();
      expect(screen.getByText("Test Artist")).toBeInTheDocument();
      expect(screen.getByText("2023")).toBeInTheDocument();
      expect(screen.queryByText("?")).not.toBeInTheDocument();
    });

    test("shows by default", () => {
      render(TrackCard, { props: { track: mockTrack } });

      expect(screen.getByText("Test Song")).toBeInTheDocument();
      expect(screen.getByText("Test Artist")).toBeInTheDocument();
      expect(screen.getByText("2023")).toBeInTheDocument();
    });

    test("hides when track is not revealed", () => {
      render(TrackCard, { props: { track: mockTrack, revealed: false } });

      expect(screen.getByText("?")).toBeInTheDocument();
      expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
      expect(screen.queryByText("Test Artist")).not.toBeInTheDocument();
      expect(screen.queryByText("2023")).not.toBeInTheDocument();
    });
  });

  describe("user avatar", () => {
    test("shows when track is not revealed and user provided", () => {
      render(TrackCard, {
        props: { track: mockTrack, revealed: false, user: mockUser },
      });

      const avatarImg = screen.getByRole("img", { name: mockUser.name });
      expect(avatarImg).toBeInTheDocument();
      expect(avatarImg).toHaveAttribute("src", mockUser.avatar_url);
      expect(avatarImg).toHaveAttribute("alt", mockUser.name);
    });

    test("shows for different users", () => {
      const differentUser = {
        name: "Another Player",
        avatar_url: "https://example.com/different-avatar.png",
      };

      render(TrackCard, {
        props: { track: mockTrack, revealed: false, user: differentUser },
      });

      const avatarImg = screen.getByRole("img", { name: differentUser.name });
      expect(avatarImg).toBeInTheDocument();
      expect(avatarImg).toHaveAttribute("src", differentUser.avatar_url);
      expect(avatarImg).toHaveAttribute("alt", differentUser.name);
    });

    test("hides when user is null", () => {
      render(TrackCard, {
        props: { track: mockTrack, revealed: false, user: null },
      });

      expect(screen.queryByRole("img")).not.toBeInTheDocument();
    });

    test("hides when user prop is omitted", () => {
      render(TrackCard, {
        props: { track: mockTrack, revealed: false },
      });

      expect(screen.queryByRole("img")).not.toBeInTheDocument();
    });

    test("hides when track is revealed", () => {
      render(TrackCard, {
        props: { track: mockTrack, revealed: true, user: mockUser },
      });

      expect(
        screen.queryByRole("img", { name: mockUser.name })
      ).not.toBeInTheDocument();
    });
  });
});
