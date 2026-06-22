import { createElement } from "react"

import("@inertiajs/react").then(m => { window.__inertiaRouter = m.router }).catch(() => {})

function rubyNativePlatform() {
  if (typeof navigator === "undefined") return null
  const ua = navigator.userAgent || ""
  if (ua.includes("Ruby Native iOS")) return "ios"
  if (ua.includes("Ruby Native Android")) return "android"
  return null
}

// "ios" | "android" when running inside a Ruby Native wrapper, else null.
export function nativePlatform() {
  return rubyNativePlatform()
}

// Send a message over the native bridge. No-ops (returns false) on the web,
// during SSR, or before the wrapper has injected `window.RubyNative`.
export function nativePostMessage(message) {
  if (typeof window === "undefined") return false
  const bridge = window.RubyNative
  if (!bridge || typeof bridge.postMessage !== "function") return false
  bridge.postMessage(message)
  return true
}

// Pop the native navigation stack. Mirrors `native_back_button_tag`.
export function nativeBack() {
  return nativePostMessage({ action: "back" })
}

function resolveIcon(icon, icons) {
  if (icons) {
    const platform = rubyNativePlatform()
    if (platform && icons[platform]) return icons[platform]
  }
  return icon
}

export function NativeTabs({ enabled = true }) {
  if (!enabled) return null
  return createElement("div", { "data-native-tabs": true, hidden: true })
}

export function NativePush() {
  return createElement("div", { "data-native-push": true, hidden: true })
}

export function NativeForm() {
  return createElement("div", { "data-native-form": true, hidden: true })
}

export function NativeReview() {
  return createElement("div", { "data-native-review": true, hidden: true })
}

export function NativeNavbar({ title = "", pullToRefresh = true, children }) {
  const props = { "data-native-navbar": title, hidden: true }
  if (!pullToRefresh) props["data-native-pull-to-refresh"] = "false"
  return createElement("div", props, children)
}

export function NativeButton({ position = "trailing", icon, icons, title, href, click, selected, children }) {
  const resolved = resolveIcon(icon, icons)
  const props = { "data-native-button": true }
  if (resolved) props["data-native-icon"] = resolved
  if (title) props["data-native-title"] = title
  if (href) props["data-native-href"] = href
  if (click) props["data-native-click"] = click
  if (position) props["data-native-position"] = position
  if (selected) props["data-native-selected"] = ""
  return createElement("div", props, children)
}

export function NativeMenuItem({ title, href, click, icon, icons, selected }) {
  const resolved = resolveIcon(icon, icons)
  const props = { "data-native-menu-item": true }
  if (title) props["data-native-title"] = title
  if (href) props["data-native-href"] = href
  if (click) props["data-native-click"] = click
  if (resolved) props["data-native-icon"] = resolved
  if (selected) props["data-native-selected"] = ""
  return createElement("div", props)
}

export function NativeFab({ icon, icons, href, click }) {
  const resolved = resolveIcon(icon, icons)
  if (!resolved) throw new Error("NativeFab requires `icon` or `icons`")
  const props = { "data-native-fab": true, "data-native-icon": resolved, hidden: true }
  if (href) props["data-native-href"] = href
  if (click) props["data-native-click"] = click
  return createElement("div", props)
}

export function NativeOverscroll({ top, bottom }) {
  return createElement("div", {
    "data-native-overscroll-top": top,
    "data-native-overscroll-bottom": bottom || top,
    hidden: true
  })
}

export function NativeSubmitButton({ title = "Save", click = "[type='submit']" }) {
  return createElement("div", {
    "data-native-submit-button": true,
    "data-native-title": title,
    "data-native-click": click,
    hidden: true
  })
}

export function NativeBadge({ count, home, tab }) {
  if (count != null && home == null) home = count
  if (count != null && tab == null) tab = count
  const props = { "data-native-badge": "", hidden: true }
  if (home != null) props["data-native-badge-home"] = home
  if (tab != null) props["data-native-badge-tab"] = tab
  return createElement("div", props)
}

// A visible back button that pops the native navigation stack on tap.
// Renders a chevron by default; pass children to supply your own content.
// Extra props (className, aria-label, style, ...) are forwarded to the button.
export function NativeBackButton({ children, className, onClick, ...rest }) {
  const classes = ["native-back-button", className].filter(Boolean).join(" ")
  const handleClick = event => {
    if (onClick) onClick(event)
    if (!event.defaultPrevented) nativeBack()
  }
  const content = children != null ? children : createElement(
    "svg",
    { width: 24, height: 24, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 2.5, "aria-hidden": true },
    createElement("path", { d: "M15.75 19.5L8.25 12l7.5-7.5", strokeLinecap: "round", strokeLinejoin: "round" })
  )
  return createElement("button", { type: "button", ...rest, className: classes, onClick: handleClick }, content)
}

export function nativeHaptic(feedback = "success", data = {}) {
  return { ...data, "data-native-haptic": feedback }
}

