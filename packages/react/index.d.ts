import * as React from "react"

export type NativePlatform = "ios" | "android"

/** Per-platform icon overrides, e.g. `{ ios: "bag", android: "shopping_cart" }`. */
export interface NativeIcons {
  ios?: string
  android?: string
}

export interface NativeTabsProps {
  /** Render the tab bar. Defaults to `true`. */
  enabled?: boolean
}
export function NativeTabs(props: NativeTabsProps): React.ReactElement | null

export function NativePush(): React.ReactElement

export function NativeForm(): React.ReactElement

export function NativeReview(): React.ReactElement

export interface NativeNavbarProps {
  /** Navigation bar title. */
  title?: string
  /** Enable pull-to-refresh on this page. Defaults to `true`. */
  pullToRefresh?: boolean
  /** `NativeButton` / `NativeSubmitButton` children to place in the bar. */
  children?: React.ReactNode
}
export function NativeNavbar(props: NativeNavbarProps): React.ReactElement

export interface NativeButtonProps {
  /** Side of the navigation bar. Defaults to `"trailing"`. */
  position?: "leading" | "trailing"
  /** Icon name applied to every platform. */
  icon?: string
  /** Per-platform icon overrides; a matching entry wins over `icon`. */
  icons?: NativeIcons
  title?: string
  /** Navigate to this URL on tap. */
  href?: string
  /** CSS selector to click on tap (alternative to `href`). */
  click?: string
  selected?: boolean
  /** `NativeMenuItem` children turn the button into a menu. */
  children?: React.ReactNode
}
export function NativeButton(props: NativeButtonProps): React.ReactElement

export interface NativeMenuItemProps {
  title?: string
  href?: string
  click?: string
  icon?: string
  icons?: NativeIcons
  selected?: boolean
}
export function NativeMenuItem(props: NativeMenuItemProps): React.ReactElement

export interface NativeFabProps {
  /** Icon name applied to every platform. Required unless `icons` is given. */
  icon?: string
  /** Per-platform icon overrides; a matching entry wins over `icon`. */
  icons?: NativeIcons
  href?: string
  click?: string
}
export function NativeFab(props: NativeFabProps): React.ReactElement

export interface NativeOverscrollProps {
  /** Top overscroll color. */
  top: string
  /** Bottom overscroll color. Defaults to `top`. */
  bottom?: string
}
export function NativeOverscroll(props: NativeOverscrollProps): React.ReactElement

export interface NativeSubmitButtonProps {
  /** Button label. Defaults to `"Save"`. */
  title?: string
  /** CSS selector to click on tap. Defaults to `"[type='submit']"`. */
  click?: string
}
export function NativeSubmitButton(props: NativeSubmitButtonProps): React.ReactElement

export interface NativeBadgeProps {
  /** Sets both `home` and `tab` when they are not given individually. */
  count?: number
  /** Home screen icon badge count. */
  home?: number
  /** Tab bar icon badge count. */
  tab?: number
}
export function NativeBadge(props: NativeBadgeProps): React.ReactElement

export interface NativeBackButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Custom button content. Defaults to a chevron icon. */
  children?: React.ReactNode
}
/**
 * A visible back button that pops the native navigation stack on tap. Extra
 * props are forwarded to the underlying `<button>`. A supplied `onClick` runs
 * first; calling `event.preventDefault()` in it cancels the native back.
 */
export function NativeBackButton(props: NativeBackButtonProps): React.ReactElement

/** Returns the current native platform, or `null` on the web / during SSR. */
export function nativePlatform(): NativePlatform | null

/**
 * Send a message over the native bridge. Returns `false` (a no-op) on the web,
 * during SSR, or before the wrapper has injected `window.RubyNative`.
 */
export function nativePostMessage(message: unknown): boolean

/** Pop the native navigation stack. Returns `false` when not in a native app. */
export function nativeBack(): boolean

/**
 * Returns props to spread onto a clickable element so tapping it triggers
 * native haptic feedback.
 */
export function nativeHaptic(
  feedback?: string,
  data?: Record<string, unknown>
): Record<string, unknown> & { "data-native-haptic": string }

declare global {
  interface Window {
    RubyNative?: {
      postMessage(message: unknown): void
      [key: string]: unknown
    }
  }
}
