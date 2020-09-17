set(HTML_SRC_FILES
    
    monocle.html
    pdf.html
    instantslider.js
    styling.js
    
    monocle/scripts/monocore.js
    monocle/scripts/monoctrl.js
    monocle/styles/monocore.css
    monocle/styles/monoctrl.css
)

if(${OUT_OF_TREE_BUILD})
    foreach( SRC_FILE ${HTML_SRC_FILES} )
        configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${SRC_FILE})
    endforeach( SRC_FILE )
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR} DESTINATION ${CMAKE_BINARY_DIR})
endif(${OUT_OF_TREE_BUILD})

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} DESTINATION ${DATA_DIR}
    PATTERN "[Cc][Mm]ake*" EXCLUDE)
