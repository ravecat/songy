import { render, screen } from "@testing-library/svelte";
import { expect, test, describe } from "vitest";

import Vinyl from "~components/Vinyl.svelte";

describe("Vinyl", () => {
  test("renders vinyl disc structure", () => {
    const { container } = render(Vinyl);

    expect(container.querySelector(".vinyl-disc")).toBeInTheDocument();
    expect(container.querySelector(".vinyl-disc__grooves")).toBeInTheDocument();
    expect(container.querySelector(".vinyl-disc__shine")).toBeInTheDocument();
    expect(container.querySelector(".vinyl-disc__label")).toBeInTheDocument();
    expect(container.querySelector(".vinyl-disc__spindle")).toBeInTheDocument();
  });

  test("renders default SVG pattern when no children", () => {
    const { container } = render(Vinyl);

    const pattern = container.querySelector(".vinyl-disc__label-pattern");
    expect(pattern).toBeInTheDocument();
    expect(pattern.tagName.toLowerCase()).toBe("svg");
  });

  test("applies custom spin duration", () => {
    const { container } = render(Vinyl, { props: { duration: 4 } });

    const disc = container.querySelector(".vinyl-disc");
    expect(disc).toHaveStyle("--spin-duration: 4s");
  });

  test("applies default spin duration of 8 seconds", () => {
    const { container } = render(Vinyl);

    const disc = container.querySelector(".vinyl-disc");
    expect(disc).toHaveStyle("--spin-duration: 8s");
  });

  test("applies counter-rotate class when still prop is true", () => {
    const { container } = render(Vinyl, { props: { still: true } });

    const label = container.querySelector(".vinyl-disc__label");
    expect(label).toHaveClass("vinyl-disc__label_counter-rotate");
  });

  test("does not apply counter-rotate class when still prop is false", () => {
    const { container } = render(Vinyl, { props: { still: false } });

    const label = container.querySelector(".vinyl-disc__label");
    expect(label).not.toHaveClass("vinyl-disc__label_counter-rotate");
  });

  test("default pattern contains colored shapes", () => {
    const { container } = render(Vinyl);

    const polygons = container.querySelectorAll(
      ".vinyl-disc__label-pattern polygon",
    );
    expect(polygons.length).toBeGreaterThan(0);
  });
});
