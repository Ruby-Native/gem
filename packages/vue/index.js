import { defineComponent, h } from "vue"

/**
 * Per-platform icon names. iOS uses SF Symbols, Android uses Material icons.
 * @typedef {object} NativeIcons
 * @property {string} [ios]
 * @property {string} [android]
 */

/**
 * @typedef {"success" | "warning" | "error" | "impact" | "selection"} NativeHapticFeedback
 */

/**
 * "title" turns the nav-bar title into a dropdown menu. Give the button a
 * `menu` and no icon or label of its own.
 * @typedef {"leading" | "trailing" | "title"} NativeButtonPosition
 */

/**
 * How a menu item's page lands. "replace" swaps the current history entry,
 * which is what a page switcher wants.
 * @typedef {"push" | "replace"} NativeAction
 */

import("@inertiajs/vue3").then(m => { window.__inertiaRouter = m.router }).catch(() => {})

function rubyNativePlatform() {
  if (typeof navigator === "undefined") return null
  const ua = navigator.userAgent || ""
  if (ua.includes("Ruby Native iOS")) return "ios"
  if (ua.includes("Ruby Native Android")) return "android"
  return null
}

/**
 * @param {string} [icon]
 * @param {NativeIcons} [icons]
 * @returns {string | undefined}
 */
function resolveIcon(icon, icons) {
  if (icons) {
    const platform = rubyNativePlatform()
    if (platform && icons[platform]) return icons[platform]
  }
  return icon
}

/**
 * Sends a message over the native bridge. Deliberately not exported: app code
 * talks to the app through signal elements, not the raw message protocol.
 * @param {Record<string, unknown>} message
 * @returns {boolean}
 */
function postMessage(message) {
  if (typeof window === "undefined") return false
  const bridge = window.RubyNative
  if (!bridge || typeof bridge.postMessage !== "function") return false
  bridge.postMessage(message)
  return true
}

/**
 * Returns "ios" or "android" inside a Ruby Native app, and null on the web.
 * The counterpart of the `native_platform` Rails helper.
 * @returns {"ios" | "android" | null}
 */
export function nativePlatform() {
  return rubyNativePlatform()
}

export const NativeTabs = defineComponent({
  name: "NativeTabs",
  props: {
    enabled: { type: Boolean, default: true }
  },
  render() {
    if (!this.enabled) return null
    return h("div", { "data-native-tabs": true, hidden: true })
  }
})

export const NativePush = defineComponent({
  name: "NativePush",
  render() {
    return h("div", { "data-native-push": true, hidden: true })
  }
})

export const NativeForm = defineComponent({
  name: "NativeForm",
  render() {
    return h("div", { "data-native-form": true, hidden: true })
  }
})

// Declares that this page lands as a root, with nothing behind it and no back
// affordance. Emits only the element half of `native_presentation_tag`, so
// Advanced Mode applies it once the page has rendered rather than before the
// navigation commits. Set the `Native-Presentation` response header from the
// controller as well to get the earlier path.
export const NativePresentation = defineComponent({
  name: "NativePresentation",
  props: { intent: { type: String, default: "root" } },
  render() {
    return h("div", { "data-native-presentation": this.intent, hidden: true })
  }
})

export const NativeReview = defineComponent({
  name: "NativeReview",
  render() {
    return h("div", { "data-native-review": true, hidden: true })
  }
})

export const NativeNavbar = defineComponent({
  name: "NativeNavbar",
  props: {
    title: { type: String, default: "" },
    pullToRefresh: { type: Boolean, default: true }
  },
  render() {
    /** @type {Record<string, any>} */
    const props = { "data-native-navbar": this.title, hidden: true }
    if (!this.pullToRefresh) props["data-native-pull-to-refresh"] = "false"
    return h("div", props, this.$slots.default?.())
  }
})

export const NativeButton = defineComponent({
  name: "NativeButton",
  props: {
    position: { type: /** @type {import("vue").PropType<NativeButtonPosition>} */ (String), default: /** @type {NativeButtonPosition} */ ("trailing") },
    icon: String,
    icons: /** @type {import("vue").PropType<NativeIcons>} */ (Object),
    title: String,
    href: String,
    click: String,
    selected: { type: Boolean, default: undefined }
  },
  render() {
    const resolved = resolveIcon(this.icon, this.icons)
    /** @type {Record<string, any>} */
    const attrs = { "data-native-button": true }
    if (resolved) attrs["data-native-icon"] = resolved
    if (this.title) attrs["data-native-title"] = this.title
    if (this.href) attrs["data-native-href"] = this.href
    if (this.click) attrs["data-native-click"] = this.click
    if (this.position) attrs["data-native-position"] = this.position
    if (this.selected) attrs["data-native-selected"] = ""
    return h("div", attrs, this.$slots.default?.())
  }
})

export const NativeMenuItem = defineComponent({
  name: "NativeMenuItem",
  props: {
    title: String,
    href: String,
    click: String,
    icon: String,
    icons: /** @type {import("vue").PropType<NativeIcons>} */ (Object),
    selected: { type: Boolean, default: undefined },
    action: /** @type {import("vue").PropType<NativeAction>} */ (String)
  },
  render() {
    const resolved = resolveIcon(this.icon, this.icons)
    /** @type {Record<string, any>} */
    const attrs = { "data-native-menu-item": true }
    if (this.title) attrs["data-native-title"] = this.title
    if (this.href) attrs["data-native-href"] = this.href
    if (this.click) attrs["data-native-click"] = this.click
    if (resolved) attrs["data-native-icon"] = resolved
    if (this.selected) attrs["data-native-selected"] = ""
    if (this.action) attrs["data-native-action"] = this.action
    return h("div", attrs)
  }
})

/**
 * A segmented button in the nav bar. Render the same set on each sibling page
 * and mark the current one `selected`. iOS only.
 */
export const NativeSegment = defineComponent({
  name: "NativeSegment",
  props: {
    title: String,
    href: String,
    click: String,
    selected: { type: Boolean, default: undefined }
  },
  render() {
    /** @type {Record<string, any>} */
    const attrs = { "data-native-segment": "" }
    if (this.title) attrs["data-native-title"] = this.title
    if (this.href) attrs["data-native-href"] = this.href
    if (this.click) attrs["data-native-click"] = this.click
    if (this.selected) attrs["data-native-selected"] = ""
    return h("div", attrs)
  }
})

export const NativeShareButton = defineComponent({
  name: "NativeShareButton",
  props: {
    position: { type: /** @type {import("vue").PropType<NativeButtonPosition>} */ (String), default: /** @type {NativeButtonPosition} */ ("trailing") },
    title: { type: String, default: "Share" },
    icon: { type: String, default: "square.and.arrow.up" },
    icons: /** @type {import("vue").PropType<NativeIcons>} */ (Object),
    url: String
  },
  render() {
    const resolved = resolveIcon(this.icon, this.icons)
    /** @type {Record<string, any>} */
    const attrs = { "data-native-button": true, "data-native-share": "" }
    if (this.title) attrs["data-native-title"] = this.title
    if (resolved) attrs["data-native-icon"] = resolved
    if (this.position) attrs["data-native-position"] = this.position
    if (this.url) attrs["data-native-share-url"] = this.url
    return h("div", attrs)
  }
})

export const NativeShareMenuItem = defineComponent({
  name: "NativeShareMenuItem",
  props: {
    title: { type: String, default: "Share" },
    url: String,
    icon: { type: String, default: "square.and.arrow.up" },
    icons: /** @type {import("vue").PropType<NativeIcons>} */ (Object),
    selected: { type: Boolean, default: undefined }
  },
  render() {
    const resolved = resolveIcon(this.icon, this.icons)
    /** @type {Record<string, any>} */
    const attrs = { "data-native-menu-item": true, "data-native-share": "", "data-native-title": this.title }
    if (this.url) attrs["data-native-share-url"] = this.url
    if (resolved) attrs["data-native-icon"] = resolved
    if (this.selected) attrs["data-native-selected"] = ""
    return h("div", attrs)
  }
})

export const NativeFab = defineComponent({
  name: "NativeFab",
  props: {
    icon: String,
    icons: /** @type {import("vue").PropType<NativeIcons>} */ (Object),
    href: String,
    click: String
  },
  render() {
    const resolved = resolveIcon(this.icon, this.icons)
    if (!resolved) throw new Error("NativeFab requires `icon` or `icons`")
    /** @type {Record<string, any>} */
    const attrs = { "data-native-fab": true, "data-native-icon": resolved, hidden: true }
    if (this.href) attrs["data-native-href"] = this.href
    if (this.click) attrs["data-native-click"] = this.click
    return h("div", attrs)
  }
})

export const NativeOverscroll = defineComponent({
  name: "NativeOverscroll",
  props: {
    top: { type: String, required: true },
    bottom: String
  },
  render() {
    return h("div", {
      "data-native-overscroll-top": this.top,
      "data-native-overscroll-bottom": this.bottom || this.top,
      hidden: true
    })
  }
})

export const NativeSubmitButton = defineComponent({
  name: "NativeSubmitButton",
  props: {
    title: { type: String, default: "Save" },
    click: { type: String, default: "[type='submit']" }
  },
  render() {
    return h("div", {
      "data-native-submit-button": true,
      "data-native-title": this.title,
      "data-native-click": this.click,
      hidden: true
    })
  }
})

export const NativeBadge = defineComponent({
  name: "NativeBadge",
  props: {
    count: { type: Number, default: undefined },
    home: { type: Number, default: undefined },
    tab: { type: Number, default: undefined }
  },
  render() {
    let home = this.home
    let tab = this.tab
    if (this.count != null && home == null) home = this.count
    if (this.count != null && tab == null) tab = this.count
    /** @type {Record<string, any>} */
    const attrs = { "data-native-badge": "", hidden: true }
    if (home != null) attrs["data-native-badge-home"] = home
    if (tab != null) attrs["data-native-badge-tab"] = tab
    return h("div", attrs)
  }
})

/**
 * A visible button that pops the native navigation stack on tap. Renders a
 * chevron unless you pass default slot content. The counterpart of the
 * `native_back_button_tag` Rails helper.
 */
export const NativeBackButton = defineComponent({
  name: "NativeBackButton",
  render() {
    const content = this.$slots.default?.() || h("svg", {
      width: 24, height: 24, viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 2.5, "aria-hidden": true
    }, [
      h("path", { d: "M15.75 19.5L8.25 12l7.5-7.5", "stroke-linecap": "round", "stroke-linejoin": "round" })
    ])
    return h("button", {
      type: "button",
      class: "native-back-button",
      onClick: () => postMessage({ action: "back" })
    }, content)
  }
})

/**
 * @param {NativeHapticFeedback} [feedback]
 * @param {Record<string, unknown>} [data]
 * @returns {Record<string, unknown>}
 */
export function nativeHaptic(feedback = "success", data = {}) {
  return { ...data, "data-native-haptic": feedback }
}
