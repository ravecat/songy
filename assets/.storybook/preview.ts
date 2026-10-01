import type { RequestHandler } from "msw";
import { initialize, mswLoader } from "msw-storybook-addon";
import type { Preview } from "@storybook/svelte-vite";
import { withThemeByDataAttribute } from "@storybook/addon-themes";
import { withInertiaPage } from "./decorators/inertia/decorator";
import { socketHandlers } from "../tests/msw";
import { avatarHandlers } from "../stories/msw";
import "../css/app.css";
import "./preview.css";

const storybookUserToken = "storybook-user-token";

window.userToken ??= storybookUserToken;

initialize(
  {
    onUnhandledRequest: "bypass",
    quiet: true,
    serviceWorker: {
      url: new URL("mockServiceWorker.js", new URL(".", window.location.href))
        .pathname,
    },
  },
  [...socketHandlers, ...avatarHandlers] as unknown as RequestHandler[],
);

const preview = {
  parameters: {
    layout: "fullscreen",
    viewport: {
      options: {
        desktop: {
          name: "Desktop",
          styles: { width: "1280px", height: "720px" },
          type: "desktop",
        },
        tablet: {
          name: "Tablet landscape",
          styles: { width: "1024px", height: "640px" },
          type: "tablet",
        },
        mobile: {
          name: "Mobile",
          styles: { width: "320px", height: "900px" },
          type: "mobile",
        },
      },
    },
  },
  initialGlobals: {
    viewport: { value: "desktop", isRotated: false },
  },
  loaders: [mswLoader],
  decorators: [
    withThemeByDataAttribute({
      themes: { light: "light", dark: "dark" },
      defaultTheme: "light",
      attributeName: "data-theme",
    }),
    withInertiaPage,
  ],
} satisfies Preview;

export default preview;
