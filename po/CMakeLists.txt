# Based on the Ubuntu Weather App

include(FindGettext)
find_program(GETTEXT_XGETTEXT_EXECUTABLE xgettext)

file(GLOB I18N_SRC_FILES
     RELATIVE ${CMAKE_SOURCE_DIR}
     ${CMAKE_SOURCE_DIR}/ui/qml/*.qml )
# DefaultCover.qml doesn't have any translatable strings, but it does confuse xgettext.
list(REMOVE_ITEM I18N_SRC_FILES ${CMAKE_SOURCE_DIR}/ui/qml/DefaultCover.qml)

set(POT_FILE ${APP_HARDCODE}.pot)
file(GLOB PO_FILES *.po)

# Create the .pot file containing the translations template
# Note that I18N_SRC_FILES was generated from the source directory
# listing, but xgettext is being run in the binary directory.
add_custom_target(${POT_FILE} ALL
    COMMENT "Generating translation template"
    COMMAND ${GETTEXT_XGETTEXT_EXECUTABLE} -o ${POT_FILE}
        -D ${CMAKE_SOURCE_DIR}
        --from-code=UTF-8
        -L javascript --qt --add-comments=/
        --keyword=tr --keyword=tr:1,2
        --package-name='${PROJECT_NAME}'
        --copyright-holder='Emanuele Sorce, Robert Schroll and others'
        --msgid-bugs-address='emanuele.sorce@hotmail.com'
        ${I18N_SRC_FILES}
    COMMAND ${CMAKE_COMMAND} -E copy ${POT_FILE} ${CMAKE_CURRENT_SOURCE_DIR})
    
# Build the binary translations catalog for each language
# it finds source translations (*.po) for
foreach(PO_FILE ${PO_FILES})
    get_filename_component(LANG ${PO_FILE} NAME_WE)
    gettext_process_po_files(${LANG} ALL PO_FILES ${PO_FILE})
    if(CLICK_MODE)
		set(INSTALL_DIR ${CMAKE_INSTALL_LOCALEDIR}/${LANG}/LC_MESSAGES)
    else(CLICK_MODE)
		set(INSTALL_DIR /usr/share/locale/${LANG}/LC_MESSAGES)
    endif(CLICK_MODE)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LANG}.gmo
            DESTINATION ${INSTALL_DIR}
			RENAME ${PROJECT_NAME}.mo)
endforeach(PO_FILE)
