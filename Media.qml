import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

     property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool barIsVertical: (Config.runtime.bar.position === "left" || Config.runtime.bar.position === "right")

    property bool hasMedia: activePlayer != null && activePlayer.playbackState !== MprisPlaybackState.Stopped
    readonly property bool isPlaying: (activePlayer != null && activePlayer.playbackState === MprisPlaybackState.Playing)

    readonly property string trackTitle: StringUtils.cleanMusicTitle(activePlayer ? activePlayer.trackTitle : "") || ""
    readonly property string trackArtist: (activePlayer ? activePlayer.trackArtist : "") || ""
    readonly property string fullText: trackTitle + (trackArtist ? " • " + trackArtist : "")

    property int customSize: Config.options.bar.mediaPlayer.customSize
    property bool useCustomSize: Config.options.bar.mediaPlayer.useCustomSize
    
    // CAMBIO 1: Límite máximo aumentado a 400 para textos largos
    property int maxWidth: 400

    readonly property int kWaveBandHeight: 18
    readonly property real kWaveOpacity: 0.22
    readonly property real kWaveLineWidth: 2.5
    readonly property int kWaveSpeedMs: 33
    readonly property real kWaveAmp: 1.2

    Layout.fillHeight: true
    clip: true

    implicitWidth: hasMedia
                   ? (useCustomSize ? customSize : Math.min(rowLayout.implicitWidth + 20, maxWidth))
                   : 0
    implicitHeight: Appearance.sizes.barHeight

    visible: implicitWidth > 0
    opacity: hasMedia ? 1 : 0

    Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Timer {
        running: root.hasMedia && root.isPlaying
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: {
            if (root.activePlayer) root.activePlayer.positionChanged()
        }
    }

    MouseArea {
        id: mouseControl
        anchors.fill: parent
        hoverEnabled: true
        z: 0 // Fondo
        preventStealing: true
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton

        onPressed: function (event) {
            event.accepted = true
            if (!root.activePlayer) return

            if (event.button === Qt.MiddleButton) {
                root.activePlayer.togglePlaying()
            } else if (event.button === Qt.BackButton) {
                root.activePlayer.previous()
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                root.activePlayer.next()
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }

        onWheel: function (wheel) {
            wheel.accepted = true
            if (wheel.angleDelta.y > 0) Audio.incrementVolume()
            else Audio.decrementVolume()
        }
    }

    RowLayout {
        id: rowLayout
        spacing: 8
        anchors.fill: parent
        anchors.rightMargin: 10
        visible: root.hasMedia

           BongoCat {
            id: bongo
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 5
            visible: root.hasMedia
            animate: root.isPlaying
            Layout.preferredHeight: Math.max(22, root.implicitHeight - 8)
            Layout.preferredWidth: Math.round(Layout.preferredHeight * 1.35)
            gifSource: "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/bongo-cat.gif"
            isVertical: root.barIsVertical
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 1; radius: 4; samples: 8
                color: Qt.rgba(0, 0, 0, 0.2)
            }
        }

          Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 24
            implicitHeight: 24

            ClippedFilledCircularProgress {
                id: mediaCircProg
                anchors.centerIn: parent
                lineWidth: Appearance.rounding.unsharpen
                value: (root.activePlayer && root.activePlayer.length > 0) ? (root.activePlayer.position / root.activePlayer.length) : 0
                implicitSize: 24
                colPrimary: Appearance.colors.colOnSecondaryContainer
                enableAnimation: false

                Item {
                    anchors.centerIn: parent
                    width: mediaCircProg.implicitSize
                    height: mediaCircProg.implicitSize

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: (root.activePlayer && root.activePlayer.isPlaying) ? "pause" : "music_note"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            // MouseArea exclusivo para el botón
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                z: 101 // Encima del MouseArea general
                onClicked: {
                    if (root.activePlayer) root.activePlayer.togglePlaying()
                }
            }
        }

        Item {
            id: marqueeViewport
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            implicitWidth: scrollingText.contentWidth

            Item {
                id: movingStrip
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                x: 0
                width: Math.max(scrollingText.contentWidth, marqueeViewport.width)

                property bool shouldScroll: scrollingText.contentWidth > marqueeViewport.width
                function reset() { movingStrip.x = 0 }

                SequentialAnimation on x {
                    running: movingStrip.shouldScroll && root.hasMedia
                    loops: Animation.Infinite
                    PauseAnimation { duration: 2000 }
                    NumberAnimation {
                        from: 0
                        to: -(scrollingText.contentWidth - marqueeViewport.width)
                        duration: Math.max(2500, scrollingText.contentWidth * 18)
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 1000 }
                    PropertyAction { target: movingStrip; property: "x"; value: 0 }
                }

                Text {
                    id: scrollingText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.fullText
                    color: Appearance.colors.colOnLayer1
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    width: contentWidth

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0; verticalOffset: 1; radius: 6; samples: 16
                        color: Qt.rgba(0, 0, 0, 0.4)
                    }

                    onTextChanged: movingStrip.reset()
                }

                    Item {
                    id: waveBand
                    anchors.left: scrollingText.left
                    anchors.right: scrollingText.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    height: root.kWaveBandHeight
                    opacity: root.hasMedia ? 1 : 0
                    visible: root.hasMedia

                    property real phase: 0

                    Timer {
                        interval: root.kWaveSpeedMs
                        running: root.hasMedia && root.isPlaying
                        repeat: true
                        onTriggered: waveBand.phase += 0.18
                    }

                    Canvas {
                        id: waveCanvas
                        anchors.fill: parent
                        antialiasing: true
                        opacity: root.kWaveOpacity * 1.5

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            var c = Appearance.m3colors.m3primary;
                            var midY = height * 0.55;
                            var amp1 = height * 0.25 * root.kWaveAmp;
                            var amp2 = height * 0.10 * root.kWaveAmp;

                            var gradient = ctx.createLinearGradient(0, 0, 0, height);
                            gradient.addColorStop(0.2, Qt.rgba(c.r, c.g, c.b, 0.8));
                            gradient.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 0.1));

                            ctx.beginPath();
                            for (var x = 0; x <= width; x += 2) {
                                var t = (x / width) * Math.PI * 2;
                                var y = midY
                                        + Math.sin(t * 2.2 + waveBand.phase) * amp1
                                        + Math.sin(t * 5.1 + waveBand.phase * 1.35) * amp2;
                                if (x === 0) ctx.moveTo(x, y);
                                else ctx.lineTo(x, y);
                            }
                            ctx.lineTo(width, height);
                            ctx.lineTo(0, height);
                            ctx.closePath();
                            
                            ctx.fillStyle = gradient;
                            ctx.fill();

                            ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.5);
                            ctx.lineWidth = 1.5;
                            ctx.beginPath();
                            for (var x2 = 0; x2 <= width; x2 += 2) {
                                var t2 = (x2 / width) * Math.PI * 2;
                                var y2 = midY + 2 
                                        + Math.sin(t2 * 1.7 + waveBand.phase * 0.95) * (amp1 * 0.75)
                                        + Math.sin(t2 * 4.7 + waveBand.phase * 1.8) * (amp2 * 0.9);
                                if (x2 === 0) ctx.moveTo(x2, y2);
                                else ctx.lineTo(x2, y2);
                            }
                            ctx.stroke();
                        }

                        Connections {
                            target: waveBand
                            function onPhaseChanged() { waveCanvas.requestPaint() }
                        }
                        Component.onCompleted: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }
                }
            }

            onWidthChanged: movingStrip.reset()
        }
    }
}
