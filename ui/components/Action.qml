/*
 * Copyright © 2018 Rodney Dawes
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

/*! Component for defining an action, for use in toolbars and menus
 *
 *  Actions provide the graphical and text properties to be presented in
 *  the application's graphical interface.
 *
 */
QtObject {
    id: action

    /** If the Action is a toggle or not. **/
    property bool checkable: false

    /** The binary state of an Action that can be toggled. **/
    property bool checked: false

    /** The color to use for the icon and/or text, if specified. **/
    property color color

    /** Whether the Action can be activated or not. **/
    property bool enabled: true

    /** The symbolic named icon to use for the Action. **/
    property string iconName

    /*! Shorctut bound to the Action.
     *
     * Must be a string, KeySequence, or list of strings or KeySequences.
     */
    property var shortcut

    /** The text label to use for the Action. **/
    property string text

    /** The text to use in a tooltip, in the event one should be shown. **/
    property string tooltip

    /*! Emitted whenever the action is toggled, if @ref checked is set.
     *
     * The corresponding handler is `onToggled`.
     */
    signal toggled(bool checked)

    /*! Emitted whenever the action is triggered through clicking on the
     *  associated button or menu item, or when the key sequence is handled.
     *
     * The corresponding handler is `onTriggered`.
     */
    signal triggered

    /*! Method to toggle or trigger the action.
     *
     * This is called by other components which consume an Action, and
     * should generally not be called by an application itself.
     */
    function trigger() {
        if (checkable) {
            checked = !checked;
        } else {
            triggered();
        }
    }

    /* When checked is changed, emit the signal.
     */
    onCheckedChanged: {
        if (checkable) {
            toggled(checked);
        }
    }
}
