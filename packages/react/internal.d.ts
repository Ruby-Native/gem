// Ambient declarations used only to type-check index.js. Not published: see
// the `files` list in package.json.
//
// Inertia is an optional peer dependency, so it is not installed here. We only
// touch its `router` export, which index.js stashes on `window` for the bridge.

declare module "@inertiajs/react" {
  export const router: unknown
}

interface Window {
  __inertiaRouter?: unknown
  RubyNative?: { postMessage?: (message: unknown) => void }
}
