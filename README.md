# ruby_native

[Ruby Native](https://rubynative.com) turns a Rails app into an iOS app, with Android in public beta. This gem is the Rails-side integration: view helpers, a YAML config file, endpoints auto-mounted at `/native`, and a CLI for previewing and deploying builds. Full docs, including the complete helper reference and config schema, live at [rubynative.com/docs](https://rubynative.com/docs).

## Installation

```ruby
gem "ruby_native"
```

The engine auto-mounts at `/native`. No route configuration needed.

## Getting started

Run the install generator:

```bash
rails generate ruby_native:install
```

This creates `config/ruby_native.yml`. Then:

1. Edit the config with your colors and tabs (see below).
2. Add the stylesheet and `viewport-fit=cover` to your layout `<head>`:

   ```erb
   <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
   <%= stylesheet_link_tag :ruby_native %>
   ```

   `viewport-fit=cover` is required for CSS `env(safe-area-inset-*)` variables to resolve to real values instead of `0`.
3. Add the tab bar to your layout `<body>`:

   ```erb
   <%= native_tabs_tag %>
   ```
4. Preview it on your phone (see below).

The full walkthrough, including safe area layout and hiding web-only navigation with `native_app?`, is at [rubynative.com/docs/setup](https://rubynative.com/docs/setup).

## Configuration

`config/ruby_native.yml` controls the native shell:

```yaml
appearance:
  tint_color: "#007AFF"
  background_color: "#FFFFFF"

tabs:
  - title: Home
    path: /
    icon: house
  - title: Profile
    path: /profile
    icon: person
```

Changes are picked up without restarting the server in development. See [rubynative.com/docs](https://rubynative.com/docs) for the full schema: appearance and dark mode, navbar branding, Advanced Mode, OAuth, and linked domains.

## Preview

Preview your app on a real device without deploying:

```bash
bundle exec ruby_native preview
```

This starts a Cloudflare tunnel and shows a QR code for the Ruby Native app to scan. Your Rails server needs to be running separately. Requires `cloudflared`:

```bash
brew install cloudflare/cloudflare/cloudflared
```

See [rubynative.com/docs/cli](https://rubynative.com/docs/cli) for `deploy`, `login`, and auto-deploying from CI.

## React and Vue

Building with Inertia instead of ERB? `@ruby-native/react` and `@ruby-native/vue` provide the same helpers as npm packages, versioned alongside this gem. See [rubynative.com/docs/inertia](https://rubynative.com/docs/inertia) for setup.

## License

MIT.
