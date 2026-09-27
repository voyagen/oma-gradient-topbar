const test = require('node:test')
const assert = require('node:assert/strict')
const { normalizeGradientSettings } = require('../BarModel.js')

const originalAppearance = { transparency: 0, color: '#000000', fadeStart: 0, fadeLength: 100 }

test('missing and malformed settings preserve the original gradient', () => {
  for (const input of [undefined, null, [], 42, 'gradient']) {
    assert.deepEqual(normalizeGradientSettings(input), originalAppearance)
  }
  assert.deepEqual(normalizeGradientSettings({}), originalAppearance)
})

test('transparency endpoints and finite rounded percentages survive', () => {
  assert.equal(normalizeGradientSettings({ transparency: 0 }).transparency, 0)
  assert.equal(normalizeGradientSettings({ transparency: 100 }).transparency, 100)
  assert.equal(normalizeGradientSettings({ transparency: 60.6 }).transparency, 61)
  assert.equal(normalizeGradientSettings({ transparency: -23 }).transparency, 0)
  assert.equal(normalizeGradientSettings({ transparency: 101.7 }).transparency, 100)
})

test('fade start accepts a solid lead-in from zero to the entire bar', () => {
  assert.equal(normalizeGradientSettings({ fadeStart: 0 }).fadeStart, 0)
  assert.equal(normalizeGradientSettings({ fadeStart: 50 }).fadeStart, 50)
  assert.equal(normalizeGradientSettings({ fadeStart: 100 }).fadeStart, 100)
  assert.equal(normalizeGradientSettings({ fadeStart: 50.6 }).fadeStart, 51)
  assert.equal(normalizeGradientSettings({ fadeStart: -10 }).fadeStart, 0)
  assert.equal(normalizeGradientSettings({ fadeStart: 150 }).fadeStart, 100)
})

test('fade length always keeps at least one percent of background', () => {
  for (const input of [0, -1, -100])
    assert.equal(normalizeGradientSettings({ fadeLength: input }).fadeLength, 1)
  assert.equal(normalizeGradientSettings({ fadeLength: 48.7 }).fadeLength, 49)
  assert.equal(normalizeGradientSettings({ fadeLength: 110 }).fadeLength, 100)
})

test('nonfinite and nonnumeric settings cannot enter geometry', () => {
  for (const input of ['60', null, NaN, Infinity, -Infinity, {}, true]) {
    assert.equal(normalizeGradientSettings({ transparency: input }).transparency, 0)
    assert.equal(normalizeGradientSettings({ fadeStart: input }).fadeStart, 0)
    assert.equal(normalizeGradientSettings({ fadeLength: input }).fadeLength, 100)
  }
})

test('only full opaque RGB reaches the gradient color', () => {
  assert.equal(normalizeGradientSettings({ color: '  #AABBCC  ' }).color, '#aabbcc')
  for (const input of ['#abc', '#aabbccdd', '#gg0000', 'red', '', 42, null])
    assert.equal(normalizeGradientSettings({ color: input }).color, '#000000')
})
