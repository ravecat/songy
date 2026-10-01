import * as a11yAnnotations from "@storybook/addon-a11y/preview";
import * as themeAnnotations from "@storybook/addon-themes/preview";
import { setProjectAnnotations } from "@storybook/svelte-vite";
import { afterEach, beforeEach, expect, inject } from "vitest";
import { cdp } from "vitest/browser";
import * as previewAnnotations from "./preview";

declare module "vitest" {
  interface ProvidedContext {
    visualGlobals: {
      theme: "light" | "dark";
      viewport: { value: "desktop" | "tablet" | "mobile" };
    };
  }
}

// The Vitest addon runs the combined beforeAll lifecycle once.
setProjectAnnotations([
  a11yAnnotations,
  themeAnnotations,
  previewAnnotations,
  { initialGlobals: inject("visualGlobals") },
]);

// Child browser projects do not trigger Storybook's automatic mouse reset.
beforeEach(async () => {
  await cdp().send("Input.dispatchMouseEvent", {
    type: "mouseMoved",
    x: -10,
    y: -10,
    buttons: 0,
  });
});

afterEach(async ({ task }) => {
  if (task.result?.state === "fail") return;

  await Promise.all(Array.from(document.fonts, (font) => font.load()));
  await document.fonts.ready;
  await Promise.all(Array.from(document.images, (image) => image.decode()));
  await expect(document.documentElement).toMatchScreenshot({ timeout: 15_000 });
});
