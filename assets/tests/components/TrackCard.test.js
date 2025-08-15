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

  test("shows ready button when ready prop is true", () => {
    render(TrackCard, { props: { track: mockTrack, revealed: false, ready: true } });

    const readyButton = screen.getByRole("button", {
      name: /mark as ready to submit guess/i,
    });
    expect(readyButton).toBeInTheDocument();
    expect(readyButton).toHaveTextContent("Ready");
  });

  test("does not show ready button when ready prop is false", () => {
    render(TrackCard, { props: { track: mockTrack, ready: false } });

    expect(
      screen.queryByRole("button", { name: /mark as ready to submit guess/i })
    ).not.toBeInTheDocument();
    expect(screen.queryByText("Ready")).not.toBeInTheDocument();
  });

  test("does not show ready button when ready prop is not provided", () => {
    render(TrackCard, { props: { track: mockTrack } });

    expect(
      screen.queryByRole("button", { name: /mark as ready to submit guess/i })
    ).not.toBeInTheDocument();
    expect(screen.queryByText("Ready")).not.toBeInTheDocument();
  });

  test("does not show ready button on revealed content", () => {
    render(TrackCard, {
      props: { track: mockTrack, revealed: true, ready: true },
    });

    expect(screen.getByText("Test Song")).toBeInTheDocument();
    expect(screen.getByText("Test Artist")).toBeInTheDocument();
    expect(screen.getByText("2023")).toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: /mark as ready to submit guess/i })
    ).not.toBeInTheDocument();
  });

  test("shows ready button with hidden content", () => {
    render(TrackCard, {
      props: { track: mockTrack, revealed: false, ready: true },
    });

    expect(screen.getByText("?")).toBeInTheDocument();
    expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /mark as ready to submit guess/i })
    ).toBeInTheDocument();
  });
});
