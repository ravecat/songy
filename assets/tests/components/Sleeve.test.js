import { render, screen } from "@testing-library/svelte";
import { expect, test, describe } from "vitest";

import Sleeve from "~components/Sleeve.svelte";

describe("Sleeve", () => {
  const mockTrack = {
    id: "track-1",
    title: "Bohemian Rhapsody",
    artist: "Queen",
    year: 1975,
    cover_url: "https://example.com/cover.jpg",
    meta: {},
  };

  test("renders sleeve container", () => {
    const { container } = render(Sleeve);

    expect(container.querySelector(".sleeve")).toBeInTheDocument();
  });

  test("displays geometric pattern when no track provided", () => {
    const { container } = render(Sleeve);

    const pattern = container.querySelector(".sleeve__pattern");
    expect(pattern).toBeInTheDocument();
    expect(pattern.tagName.toLowerCase()).toBe("svg");
  });

  test("displays geometric pattern when track has no cover_url", () => {
    const trackWithoutCover = { ...mockTrack, cover_url: null };
    const { container } = render(Sleeve, { props: { track: trackWithoutCover } });

    const pattern = container.querySelector(".sleeve__pattern");
    expect(pattern).toBeInTheDocument();
  });

  test("displays cover image when track has cover_url", () => {
    render(Sleeve, { props: { track: mockTrack } });

    const coverImg = screen.getByAltText("Bohemian Rhapsody");
    expect(coverImg).toBeInTheDocument();
    expect(coverImg).toHaveAttribute("src", "https://example.com/cover.jpg");
  });

  test("displays track info when track provided", () => {
    render(Sleeve, { props: { track: mockTrack } });

    expect(screen.getByText("Queen")).toBeInTheDocument();
    expect(screen.getByText("Bohemian Rhapsody")).toBeInTheDocument();
    expect(screen.getByText("1975")).toBeInTheDocument();
  });

  test("does not display track info when no track provided", () => {
    render(Sleeve);

    expect(screen.queryByText("Queen")).not.toBeInTheDocument();
    expect(screen.queryByText("Bohemian Rhapsody")).not.toBeInTheDocument();
  });

  test("renders overlay for darkening effect", () => {
    const { container } = render(Sleeve, { props: { track: mockTrack } });

    expect(container.querySelector(".sleeve__overlay")).toBeInTheDocument();
  });

  test("handles track without year", () => {
    const trackWithoutYear = { ...mockTrack, year: undefined };
    const { container } = render(Sleeve, { props: { track: trackWithoutYear } });

    const yearElement = container.querySelector(".sleeve__year");
    expect(yearElement).toBeInTheDocument();
    expect(yearElement.textContent).toBe("");
  });
});
