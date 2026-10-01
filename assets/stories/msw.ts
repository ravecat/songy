import { http, HttpResponse } from "msw";

const avatars = import.meta.glob<string>("./fixtures/avatars/*.svg", {
  eager: true,
  query: "?raw",
  import: "default",
});

export const avatarHandlers = [
  http.get("https://api.dicebear.com/9.x/thumbs/svg", ({ request }) => {
    const seed = new URL(request.url).searchParams.get("seed");
    const avatar = avatars[`./fixtures/avatars/${seed}.svg`];

    return new HttpResponse(avatar ?? null, {
      status: avatar ? 200 : 404,
      headers: { "Content-Type": "image/svg+xml" },
    });
  }),
];
