import { defineComponent, h } from "vue"

import("@inertiajs/vue3").then(m => { window.__inertiaRouter = m.router }).catch(() => {})

function rubyNativePlatform() {
  if (typeof navigator === "undefined") return null
  const ua = navigator.userAgent || ""
  if (ua.includes("Ruby Native iOS")) return "ios"
  if (ua.includes("Ruby Native Android")) return "android"
  return null
}

function resolveIcon(icon, icons) {
  if (icons) {
    const platform = rubyNativePlatform()
    if (platform && icons[platform]) return icons[platform]
  }
  return icon
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

export const NativeReview = defineComponent({
  name: "NativeReview",
  render() {
    return h("div", { "data-native-review": true, hidden: true })
  }
})

export const NativeNavbar = defineComponent({
  name: "NativeNavbar",
  props: { title: { type: String, default: "" } },
  render() {
    return h("div", { "data-native-navbar": this.title, hidden: true }, this.$slots.default?.())
  }
})

export const NativeButton = defineComponent({
  name: "NativeButton",
  props: {
    position: { type: String, default: "trailing" },
    icon: String,
    icons: Object,
    title: String,
    href: String,
    click: String,
    selected: { type: Boolean, default: undefined }
  },
  render() {
    const resolved = resolveIcon(this.icon, this.icons)
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
    icons: Object,
    selected: { type: Boolean, default: undefined }
  },
  render() {
    const resolved = resolveIcon(this.icon, this.icons)
    const attrs = { "data-native-menu-item": true }
    if (this.title) attrs["data-native-title"] = this.title
    if (this.href) attrs["data-native-href"] = this.href
    if (this.click) attrs["data-native-click"] = this.click
    if (resolved) attrs["data-native-icon"] = resolved
    if (this.selected) attrs["data-native-selected"] = ""
    return h("div", attrs)
  }
})

export const NativeFab = defineComponent({
  name: "NativeFab",
  props: {
    icon: String,
    icons: Object,
    href: String,
    click: String
  },
  render() {
    const resolved = resolveIcon(this.icon, this.icons)
    if (!resolved) throw new Error("NativeFab requires `icon` or `icons`")
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
