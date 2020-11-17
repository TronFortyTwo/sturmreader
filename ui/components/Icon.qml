/*
 * Copyright 2015 Canonical Ltd.
 * Copyright 2018 Rodney Dawes
 * Copyright 2020 Emanuele Sorce
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9

/*! The Icon component displays a themed icon which may have its base color
 *  swapped with the specified color.
 *
 *  Using icons whenever possible enhances consistency accross applications.
 *  Each icon has a name and can have different visual representations
 *  depending on the size requested.
 *
 *  Setting the \ref color property will colorize all pixels with the
 *  \ref baseColor (by default #808080), with the specified color.
 *
 *  Example:
 *  \code
 *  Icon {
 *      width: 48
 *      height: 48
 *      name: "go-previous"
 *  }
 *  \endcode
 *
 *  Example of colorization:
 *  \code
 *  Icon {
 *      width: 48
 *      height: 48
 *      name: "go-previous"
 *      color: "red"
 *  }
 *  \endcode
 *
 *  Icon themes are created following the
 *  [Freedesktop Icon Theme Specification](http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html).
 */
Item {
    id: iconRoot

    /** The named icon to use from the theme. **/
    property string name

    /** type:url A URL source for the Icon. Overrides \ref name if set. **/
    property alias source: iconImage.source

    /** type:color The color to colorize the Icon with. **/
    property alias color: colorMask.colorOut

    /** type:color The color to be replaced in the Icon when colorizing. **/
    property alias baseColor: colorMask.colorIn

    Image {
        id: iconImage
        objectName: "iconMask"
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit

        cache: true
        asynchronous: true
        visible: !colorMask.visible

        sourceSize.width: width
        sourceSize.height: height

        //readonly property string rtl: Qt.application.layoutDirection == Qt.RightToLeft ? "-rtl" : ""
        source: iconRoot.name ? "../Icons/" + iconRoot.name + ".svg" : ""
    }

    ShaderEffect {
        id: colorMask
        objectName: "colorMask"

        anchors.centerIn: parent
        width: iconImage.paintedWidth
        height: iconImage.paintedHeight

        // Whether or not a color has been set.
        visible: iconImage.status == Image.Ready && colorOut != Qt.rgba(0.0, 0.0, 0.0, 0.0)

        property Image source: iconImage
        property color colorOut: Qt.rgba(0.0, 0.0, 0.0, 0.0)
        property color colorIn: "#808080"
        property real threshold: 0.1

        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D source;
            uniform highp vec4 colorOut;
            uniform highp vec4 colorIn;
            uniform lowp float threshold;
            uniform lowp float qt_Opacity;
            void main() {
                lowp vec4 sourceColor = texture2D(source, qt_TexCoord0);
                gl_FragColor = mix(
                    colorOut * vec4(sourceColor.a),
                    sourceColor,
                    step(threshold, distance(
                        sourceColor.rgb / sourceColor.a,
                        colorIn.rgb))
                ) * qt_Opacity;
            }"
    }
}
