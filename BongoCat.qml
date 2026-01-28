import QtQuick
import QtQuick.Layouts

Item {
    id: bongoCat

    property bool isVertical: false
    property bool animate: true
    // Ruta al GIF
    property url gifSource: "file:///home/jcgomez91/.config/quickshell/ii/assets/gifs/bongo-cat.gif"

    implicitWidth: 56
    implicitHeight: 42
    Layout.alignment: Qt.AlignVCenter

    AnimatedImage {
        anchors.fill: parent
        source: bongoCat.gifSource
        smooth: true
        cache: true
        fillMode: Image.PreserveAspectFit
        rotation: bongoCat.isVertical ? 270 : 0

        paused: !bongoCat.animate
    }
}

