import { render, screen } from "@testing-library/svelte";
import { tick } from "svelte";
import { describe, expect, test } from "vitest";
import Timer from "~components/Timer.svelte";

describe("Timer", () => {
  test("does not render when seconds is null", async () => {
    render(Timer, { props: { seconds: null } });

    await tick();

    expect(screen.queryByRole("timer")).not.toBeInTheDocument();
  });

  test("renders remaining seconds", async () => {
    render(Timer, { props: { seconds: 12 } });
    await tick();

    expect(screen.getByRole("timer")).toHaveTextContent("12");
  });
});
