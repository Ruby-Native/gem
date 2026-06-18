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

## Helpers

- `nativeHaptic(feedback = "success", data = {})` - returns props to spread onto a clickable element so tapping it triggers native haptic feedback:

  ```jsx
  <button {...nativeHaptic("success")}>Save</button>
  ```

## Docs

Full guides at [rubynative.com/docs](https://rubynative.com/docs).

## License

MIT
