import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, vi } from "vitest";
import TrackCard from "~components/TrackCard.svelte";

describe("TrackCard - Music Timeline Game Card Component", () => {
  const mockTrack = {
    title: "Test Song",
    artist: "Test Artist",
    year: 2023,
  };

  const mockUser = {
    name: "Test User",
    avatar_url: "https://example.com/avatar.jpg",
  };

  describe("Track Content Visibility", () => {
    describe("when track is revealed", () => {
      test("displays complete track information to player", () => {
        render(TrackCard, { props: { track: mockTrack, revealed: true } });

        expect(screen.getByText("Test Song")).toBeInTheDocument();
        expect(screen.getByText("Test Artist")).toBeInTheDocument();
        expect(screen.getByText("2023")).toBeInTheDocument();
        expect(screen.queryByText("?")).not.toBeInTheDocument();
      });

      test("renders track information with default reveal state", () => {
        render(TrackCard, { props: { track: mockTrack } });

        expect(screen.getByText("Test Song")).toBeInTheDocument();
        expect(screen.getByText("Test Artist")).toBeInTheDocument();
        expect(screen.getByText("2023")).toBeInTheDocument();
      });
    });

    describe("when track is hidden", () => {
      test("shows mystery card with question mark for guessing game", () => {
        render(TrackCard, { props: { track: mockTrack, revealed: false } });

        expect(screen.getByText("?")).toBeInTheDocument();
        expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
        expect(screen.queryByText("Test Artist")).not.toBeInTheDocument();
        expect(screen.queryByText("2023")).not.toBeInTheDocument();
      });
    });
  });

  describe("Ready Button - Player Turn Submission", () => {
    describe("when player can submit their guess", () => {
      test("shows ready button on hidden track for turn completion", () => {
        render(TrackCard, {
          props: { track: mockTrack, revealed: false, ready: true },
        });

        const readyButton = screen.getByRole("button", {
          name: /mark as ready to submit guess/i,
        });
        expect(readyButton).toBeInTheDocument();
        expect(readyButton).toHaveTextContent("Ready");
      });

      test("triggers turn submission when player clicks ready", async () => {
        const onsteady = vi.fn();

        render(TrackCard, {
          props: { track: mockTrack, revealed: false, ready: true, onsteady },
        });

        const readyButton = screen.getByRole("button", {
          name: /mark as ready to submit guess/i,
        });

        await fireEvent.click(readyButton);

        expect(onsteady).toHaveBeenCalledOnce();
      });

      test("handles missing callback gracefully during turn submission", async () => {
        render(TrackCard, {
          props: { track: mockTrack, revealed: false, ready: true },
        });

        const readyButton = screen.getByRole("button", {
          name: /mark as ready to submit guess/i,
        });

        // Should not throw an error
        await fireEvent.click(readyButton);
      });
    });

    describe("when player cannot submit yet", () => {
      test("hides ready button when turn is not ready for submission", () => {
        render(TrackCard, { props: { track: mockTrack, ready: false } });

        expect(
          screen.queryByRole("button", {
            name: /mark as ready to submit guess/i,
          })
        ).not.toBeInTheDocument();
        expect(screen.queryByText("Ready")).not.toBeInTheDocument();
      });

      test("hides ready button when ready state is not provided", () => {
        render(TrackCard, { props: { track: mockTrack } });

        expect(
          screen.queryByRole("button", {
            name: /mark as ready to submit guess/i,
          })
        ).not.toBeInTheDocument();
        expect(screen.queryByText("Ready")).not.toBeInTheDocument();
      });

      test("hides ready button on revealed tracks during open play", () => {
        render(TrackCard, {
          props: { track: mockTrack, revealed: true, ready: true },
        });

        expect(screen.getByText("Test Song")).toBeInTheDocument();
        expect(screen.getByText("Test Artist")).toBeInTheDocument();
        expect(screen.getByText("2023")).toBeInTheDocument();
        expect(
          screen.queryByRole("button", {
            name: /mark as ready to submit guess/i,
          })
        ).not.toBeInTheDocument();
      });
    });
  });

  describe("User Avatar - Player Assumption Indicator", () => {
    describe("when player has made a track position assumption", () => {
      test("displays player avatar on hidden track to show ownership", () => {
        render(TrackCard, {
          props: { track: mockTrack, revealed: false, user: mockUser },
        });

        const avatarImg = screen.getByRole("img", { name: mockUser.name });
        expect(avatarImg).toBeInTheDocument();
        expect(avatarImg).toHaveAttribute("src", mockUser.avatar_url);
        expect(avatarImg).toHaveAttribute("alt", mockUser.name);
      });

      test("shows different player avatars for different assumptions", () => {
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
    });

    describe("when no player assumption exists", () => {
      test("hides avatar when no player has made assumption", () => {
        render(TrackCard, {
          props: { track: mockTrack, revealed: false, user: null },
        });

        expect(screen.queryByRole("img")).not.toBeInTheDocument();
      });

      test("hides avatar when user data is not provided", () => {
        render(TrackCard, {
          props: { track: mockTrack, revealed: false },
        });

        expect(screen.queryByRole("img")).not.toBeInTheDocument();
      });

      test("hides avatar on revealed tracks during open gameplay", () => {
        render(TrackCard, {
          props: { track: mockTrack, revealed: true, user: mockUser },
        });

        // Should show track content but no avatar
        expect(screen.getByText("Test Song")).toBeInTheDocument();
        expect(screen.getByText("Test Artist")).toBeInTheDocument();
        expect(
          screen.queryByRole("img", { name: mockUser.name })
        ).not.toBeInTheDocument();
      });
    });
  });
});
