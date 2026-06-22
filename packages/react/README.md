# @ruby-native/react

React components for [Ruby Native](https://rubynative.com). Use these in an Inertia.js + React app to emit the signal elements that Ruby Native's iOS and Android apps read to render native tabs, navigation bars, forms, and more.

## Install

```sh
npm install @ruby-native/react
```

## Usage

```jsx
import { NativeTabs, NativeNavbar, NativeButton, NativeForm } from "@ruby-native/react"

export default function Show({ product }) {
  return (
    <>
      <NativeNavbar title={product.name}>
        <NativeButton icon="bag" href="/cart" />
      </NativeNavbar>

      <NativeForm />

      {/* your page content */}
    </>
  )
}
```

Each component renders a hidden `data-native-*` signal element that the Ruby Native runtime picks up and turns into the corresponding native UI.

## Components

- `NativeTabs` - show the native tab bar
- `NativePush` - request push notification permission
- `NativeForm` - mark the current page as a form so back navigation skips it
- `NativeReview` - ask for an App Store review prompt when the page loads
- `NativeNavbar` - native navigation bar with title and buttons
- `NativeButton` - native nav bar button (icon, title, href, or click target)
- `NativeMenuItem` - item inside a native menu
- `NativeSubmitButton` - native "Save" button that submits a form
- `NativeOverscroll` - per-page overscroll colors
- `NativeBadge` - set the badge count on a home screen or tab bar icon
- `NativeFab` - floating action button (`icon`/`icons` required, plus `href` or `click`)
- `NativeBackButton` - a visible button that pops the native navigation stack

`NativeBackButton` renders a chevron by default and forwards any extra props (`className`, `aria-label`, `style`, ...) to the underlying `<button>`:

```jsx
<NativeBackButton aria-label="Go back" />
<NativeBackButton>Back</NativeBackButton>
```

## Helpers

- `nativeHaptic(feedback = "success", data = {})` - returns props to spread onto a clickable element so tapping it triggers native haptic feedback:

  ```jsx
  <button {...nativeHaptic("success")}>Save</button>
  ```

- `nativePlatform()` - returns `"ios"`, `"android"`, or `null` (web / SSR), so you can branch on the native environment.
- `nativePostMessage(message)` - send a message over the native bridge. Returns `false` (a no-op) on the web, during SSR, or before the wrapper is ready.
- `nativeBack()` - pop the native navigation stack (what `NativeBackButton` calls).

## TypeScript

Type declarations ship with the package (`index.d.ts`) - no extra `@types` install needed.

## Docs

Full guides at [rubynative.com/docs](https://rubynative.com/docs).

## License

MIT
