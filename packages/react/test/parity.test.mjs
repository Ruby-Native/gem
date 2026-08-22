import test from "node:test"
import assert from "node:assert/strict"
import { createElement } from "react"
import { renderToStaticMarkup } from "react-dom/server"

import { fixtures, hapticFixtures, parseElements, withPlatform } from "../../signal-fixtures.mjs"
import * as RubyNative from "../index.js"

function build({ component, props = {}, children = [] }) {
  const Component = RubyNative[component]
  assert.ok(Component, `@ruby-native/react does not export ${component}`)
  return createElement(Component, props, ...children.map(build))
}

for (const fixture of fixtures) {
  const platform = fixture.platform || "web"
  test(`${fixture.component} ${fixture.name} (${platform})`, async () => {
    await withPlatform(platform, async () => {
      if (fixture.throws) {
        assert.throws(() => renderToStaticMarkup(build(fixture)), error => {
          assert.match(error.message, new RegExp(escapeRegExp(fixture.throws)))
          return true
        })
      } else {
        const markup = renderToStaticMarkup(build(fixture))
        assert.deepEqual(parseElements(markup), fixture.expected)
      }
    })
  })
}

test("nativeHaptic matches the shared contract", () => {
  for (const { args, expected } of hapticFixtures) {
    assert.deepEqual(RubyNative.nativeHaptic(...args), expected)
  }
})

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}
