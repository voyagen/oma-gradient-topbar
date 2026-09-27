import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import qs.Commons
import qs.Ui

Panel {
  id: settingsRoot
  manageIpc: false
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  property string colorDraftBase: ""
  readonly property bool editable: opened && !!bar && bar.canSaveGradientSettings
  readonly property bool validColorDraft: colorField.acceptableInput && /^#[0-9a-fA-F]{6}$/.test(colorField.text)

  function syncColorDraft() {
    if (!bar) return
    var saved = bar.gradientSettings.color
    if (colorField.text === colorDraftBase) colorField.text = saved
    colorDraftBase = saved
  }

  function applyColor() {
    if (!editable || !validColorDraft) return
    var color = colorField.text.trim().toLowerCase()
    if (color === bar.gradientSettings.color) return
    if (bar.commitGradientSetting("color", color)) {
      colorField.text = color
      colorDraftBase = color
    }
  }

  onOpenedChanged: {
    if (opened) {
      colorDraftBase = bar.gradientSettings.color
      colorField.text = colorDraftBase
    } else {
      if (bar) bar.cancelGradientPreview()
      transparencySlider.dragging = false
      fadeStartSlider.dragging = false
      fadeSlider.dragging = false
      transparencySlider.liveValue = bar ? bar.gradientSettings.transparency : 0
      fadeStartSlider.liveValue = bar ? bar.gradientSettings.fadeStart : 0
      fadeSlider.liveValue = bar ? bar.gradientSettings.fadeLength : 100
      colorField.text = colorDraftBase
    }
  }

  Connections {
    target: settingsRoot.bar
    function onGradientSettingsChanged() { settingsRoot.syncColorDraft() }
    function onPositionChanged() { settingsRoot.close() }
    function onBarHiddenChanged() { if (settingsRoot.bar.barHidden) settingsRoot.close() }
  }

  Component.onDestruction: {
    button.hideOwnTooltip()
    if (bar && bar.activePopout === settingsRoot) {
      bar.cancelGradientPreview()
      bar.releasePopout(settingsRoot)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: settingsRoot.bar
    tooltipText: "Gradient settings"
    active: settingsRoot.opened
    onPressed: function(b) { if (b === Qt.LeftButton) settingsRoot.toggle() }
    iconComponent: Shape {
      id: blendShape
      readonly property real unit: width / 24
      readonly property color ink: button.active && button.useActiveColor ? button.activeColor : button.foreground
      ShapePath {
        fillColor: "transparent"
        strokeColor: blendShape.ink
        strokeWidth: 2 * blendShape.unit
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathAngleArc {
          centerX: 15 * blendShape.unit
          centerY: 9 * blendShape.unit
          radiusX: 7 * blendShape.unit
          radiusY: 7 * blendShape.unit
          startAngle: 0
          sweepAngle: 360
        }
      }
      ShapePath {
        fillColor: "transparent"
        strokeColor: blendShape.ink
        strokeWidth: 2 * blendShape.unit
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathAngleArc {
          centerX: 9 * blendShape.unit
          centerY: 15 * blendShape.unit
          radiusX: 7 * blendShape.unit
          radiusY: 7 * blendShape.unit
          startAngle: 0
          sweepAngle: 360
        }
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: settingsRoot
    bar: settingsRoot.bar
    open: settingsRoot.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: colorField.activeFocus || applyButton.activeFocus
      onCloseRequested: settingsRoot.close()
      onTabRequested: colorField.forceActiveFocus()

      ScrollView {
        id: scrollArea
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: contentColumn.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        Binding {
          target: scrollArea.contentItem
          property: "interactive"
          value: contentColumn.implicitHeight > scrollArea.height
        }

        Column {
          id: contentColumn
          width: scrollArea.availableWidth
          spacing: Style.space(14)
          enabled: settingsRoot.opened

          Text {
            text: "Gradient settings"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.title
          }

          Column {
            width: parent.width
            spacing: Style.space(5)
            Item {
              width: parent.width
              height: transparencyLabel.implicitHeight
              Text { id: transparencyLabel; text: "Transparency"; color: Color.popups.text; font.pixelSize: Style.font.body }
              Text { anchors.right: parent.right; text: settingsRoot.bar ? settingsRoot.bar.effectiveGradient.transparency + "%" : "0%"; color: Color.popups.text; font.pixelSize: Style.font.body }
            }
            PanelSlider {
              id: transparencySlider
              width: parent.width
              enabled: settingsRoot.editable
              bar: settingsRoot.bar
              minimum: 0
              maximum: 100
              integer: true
              step: 1
              value: settingsRoot.bar ? settingsRoot.bar.effectiveGradient.transparency : 0
              onMoved: function(v) { if (settingsRoot.editable) settingsRoot.bar.previewGradientSetting("transparency", v) }
              onReleased: function(v) { if (settingsRoot.editable) settingsRoot.bar.commitGradientSetting("transparency", v) }
            }
            Text { text: "0% opaque · 100% transparent"; color: Color.popups.text; font.pixelSize: Style.font.bodySmall }
          }

          Column {
            width: parent.width
            spacing: Style.space(5)
            Text { text: "Color"; color: Color.popups.text; font.pixelSize: Style.font.body }
            Row {
              width: parent.width
              spacing: Style.space(8)
              Rectangle {
                width: Style.spacing.controlHeight
                height: colorField.implicitHeight
                radius: Style.cornerRadius
                color: settingsRoot.validColorDraft ? colorField.text : (settingsRoot.bar ? settingsRoot.bar.gradientSettings.color : "#000000")
                border.color: Color.popups.border
                border.width: 1
              }
              TextField {
                id: colorField
                width: parent.width - applyButton.width - Style.spacing.controlHeight - parent.spacing * 2
                foreground: Color.popups.text
                enabled: settingsRoot.editable
                placeholderText: "#RRGGBB"
                validator: RegularExpressionValidator { regularExpression: /^#[0-9a-fA-F]{6}$/ }
                onAccepted: settingsRoot.applyColor()
                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Escape) { settingsRoot.close(); event.accepted = true }
                  else if (event.key === Qt.Key_Tab) {
                    if (applyButton.enabled) applyButton.forceActiveFocus()
                    else keyCatcher.forceActiveFocus()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Backtab) { keyCatcher.forceActiveFocus(); event.accepted = true }
                }
              }
              Button {
                id: applyButton
                text: "Apply"
                foreground: Color.popups.text
                focusable: true
                enabled: settingsRoot.editable && settingsRoot.validColorDraft
                  && !!settingsRoot.bar && colorField.text.toLowerCase() !== settingsRoot.bar.gradientSettings.color
                onClicked: settingsRoot.applyColor()
                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Escape) { settingsRoot.close(); event.accepted = true }
                  else if (event.key === Qt.Key_Tab) { keyCatcher.forceActiveFocus(); event.accepted = true }
                  else if (event.key === Qt.Key_Backtab) { colorField.forceActiveFocus(); event.accepted = true }
                }
              }
            }
            Text {
              visible: colorField.text !== "" && !settingsRoot.validColorDraft
              text: "Use a full #RRGGBB color."
              color: Color.popups.text
              font.pixelSize: Style.font.bodySmall
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(5)
            Item {
              width: parent.width
              height: fadeStartLabel.implicitHeight
              Text { id: fadeStartLabel; text: "Fade start"; color: Color.popups.text; font.pixelSize: Style.font.body }
              Text { anchors.right: parent.right; text: settingsRoot.bar ? settingsRoot.bar.effectiveGradient.fadeStart + "%" : "0%"; color: Color.popups.text; font.pixelSize: Style.font.body }
            }
            PanelSlider {
              id: fadeStartSlider
              width: parent.width
              enabled: settingsRoot.editable
              bar: settingsRoot.bar
              minimum: 0
              maximum: 100
              integer: true
              step: 1
              value: settingsRoot.bar ? settingsRoot.bar.effectiveGradient.fadeStart : 0
              onMoved: function(v) { if (settingsRoot.editable) settingsRoot.bar.previewGradientSetting("fadeStart", v) }
              onReleased: function(v) { if (settingsRoot.editable) settingsRoot.bar.commitGradientSetting("fadeStart", v) }
            }
            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              text: "Solid from the screen edge until the fade begins."
              color: Color.popups.text
              font.pixelSize: Style.font.bodySmall
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(5)
            Item {
              width: parent.width
              height: fadeLabel.implicitHeight
              Text { id: fadeLabel; text: "Fade length"; color: Color.popups.text; font.pixelSize: Style.font.body }
              Text { anchors.right: parent.right; text: settingsRoot.bar ? settingsRoot.bar.effectiveGradient.fadeLength + "%" : "100%"; color: Color.popups.text; font.pixelSize: Style.font.body }
            }
            PanelSlider {
              id: fadeSlider
              width: parent.width
              enabled: settingsRoot.editable
              bar: settingsRoot.bar
              minimum: 1
              maximum: 100
              integer: true
              step: 1
              value: settingsRoot.bar ? settingsRoot.bar.effectiveGradient.fadeLength : 100
              onMoved: function(v) { if (settingsRoot.editable) settingsRoot.bar.previewGradientSetting("fadeLength", v) }
              onReleased: function(v) { if (settingsRoot.editable) settingsRoot.bar.commitGradientSetting("fadeLength", v) }
            }
            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              text: "Distance over which the gradient fades after its solid section."
              color: Color.popups.text
              font.pixelSize: Style.font.bodySmall
            }
          }
          Text {
            visible: settingsRoot.bar && !settingsRoot.bar.canSaveGradientSettings
            text: "Gradient settings cannot be saved by this shell."
            color: Color.popups.text
            wrapMode: Text.WordWrap
            width: parent.width
            font.pixelSize: Style.font.bodySmall
          }
          Text {
            visible: settingsRoot.bar && settingsRoot.bar.gradientSaveError !== ""
            text: settingsRoot.bar ? settingsRoot.bar.gradientSaveError : ""
            color: Color.popups.text
            width: parent.width
            font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }
  }
}
