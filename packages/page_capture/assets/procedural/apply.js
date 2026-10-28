// Copyright (c) 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// you can obtain one at https://mozilla.org/MPL/2.0/.

// executeProceduralActions and its helpers from brave-core's
// components/cosmetic_filters/resources/data/content_cosmetic.ts, run once
// over the whole document. Brave's native stylesheet call is an appended
// <style>, and the result is how many elements an action applied to.
// Needs procedural_filters.js (BraveProcedural) evaluated first.
(function (proceduralActionFilters) {
  const { applyCompiledSelector, compileProceduralSelector } = BraveProcedural

  const generateRandomAttr = () => {
    const min = Number.parseInt('a000000000', 36)
    const max = Number.parseInt('zzzzzzzzzz', 36)
    return Math.floor(Math.random() * (max - min) + min).toString(36)
  }

  const globalStyleAttr = generateRandomAttr()
  const styleAttrMap = new Map()

  const injectStylesheet = (css) => {
    const style = document.createElement('style')
    style.textContent = css
    ;(document.head || document.documentElement).appendChild(style)
  }

  const getStyleAttr = (style) => {
    let styleAttr = styleAttrMap.get(style)
    if (styleAttr === undefined) {
      styleAttr = generateRandomAttr()
      styleAttrMap.set(style, styleAttr)
      const css = `[${globalStyleAttr}][${styleAttr}]{${style}}`
      injectStylesheet(css)
    }
    return styleAttr
  }

  const performAction = (element, action) => {
    if (action === undefined) {
      const attr = getStyleAttr('display: none !important')
      element.setAttribute(globalStyleAttr, '')
      element.setAttribute(attr, '')
    } else if (action.type === 'style') {
      const attr = getStyleAttr(action.arg)
      element.setAttribute(globalStyleAttr, '')
      element.setAttribute(attr, '')
    } else if (action.type === 'remove') {
      element.remove()
    } else if (action.type === 'remove-attr') {
      element.removeAttribute(action.arg)
    } else if (action.type === 'remove-class') {
      if (element.classList.contains(action.arg)) {
        element.classList.remove(action.arg)
      }
    }
  }

  let applied = 0
  for (const { selector, action } of proceduralActionFilters) {
    try {
      let matchingElements
      let startOperator

      if (selector[0].type === 'css-selector') {
        matchingElements = document.querySelectorAll(selector[0].arg)
        startOperator = 1
      } else {
        matchingElements = document.querySelectorAll('*')
        startOperator = 0
      }

      const matched =
        startOperator === selector.length
          ? Array.from(matchingElements)
          : applyCompiledSelector(
              compileProceduralSelector(selector.slice(startOperator)),
              Array.from(matchingElements),
            )
      matched.forEach((elem) => performAction(elem, action))
      applied += matched.length
    } catch (e) {
      console.error(
        'Failed to apply filter ' + JSON.stringify(selector) + ' ' + JSON.stringify(action) + ': ' + e.message,
      )
    }
  }
  return applied
})
