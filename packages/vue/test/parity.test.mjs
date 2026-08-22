import test from "node:test"
import assert from "node:assert/strict"
import { h } from "vue"
import { renderToString } from "@vue/server-renderer"

import { fixtures, hapticFixtures, parseElements, withPlatform } from "../../signal-fixtures.mjs"
import * as RubyNative from "../index.js"

function build({ component, props = {}, children = [] }) {
  const Component = RubyNative[component]
  assert.ok(Component, `@ruby-native/vue does not export ${component}`)
  if (children.length === 0) return h(Component, props)
  return h(Component, props, () => children.map(build))
}

for (const fixture of fixtures) {
  const platform = fixture.platform || "web"
  test(`${fixture.component} ${fixture.name} (${platform})`, async () => {
    await withPlatform(platform, async () => {
      if (fixture.throws) {
        await assert.rejects(async () => renderToString(build(fixture)), error => {
          assert.match(error.message, new RegExp(escapeRegExp(fixture.throws)))
          return true
        })
      } else {
        const markup = await renderToString(build(fixture))
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
