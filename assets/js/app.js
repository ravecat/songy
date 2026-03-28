import "vite/modulepreload-polyfill";
// Enable Phoenix channels
import "./socket";

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

import "phoenix_html";

/*
 * --------------------------------------------------------------------
 * Intitialize client-side Inertia app
 * --------------------------------------------------------------------
 *
 * `axios` is used for CSRF protection. More information can be found
 * in the Inertia.js Phoenix Adapter README.
 *
 * [Setting up the client-side](https://hexdocs.pm/inertia/readme.html#setting-up-the-client-side)
 *
 */
import { createInertiaApp } from "@inertiajs/svelte";
import { mount } from "svelte";
import axios from "axios";

axios.defaults.xsrfHeaderName = "x-csrf-token";

const pages = import.meta.glob("./pages/**/*.svelte", { eager: true });

createInertiaApp({
  title: (title) => (title ? `${title} - Songy` : "Songy"),
  progress: {
    delay: 250,
    color: "#29d",
  },
  resolve: (name) => {
    const page = pages[`./pages/${name}.svelte`];
    if (!page) throw new Error(`Page not found: ${name}`);
    return page;
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props });
  },
});
