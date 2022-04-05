module SharedDocument exposing (createShareDocumentDict)

import Dict exposing (Dict)
import Document exposing (Document)
import Types


getSharedDocument : Document -> Types.SharedDocument
getSharedDocument doc =
    { title = doc.title
    , id = doc.id
    , author = doc.author
    , share = doc.share
    , currentEditor = doc.currentEditor
    }


insert : Document.Document -> Types.SharedDocumentDict -> Types.SharedDocumentDict
insert doc dict =
    Dict.insert doc.id (getSharedDocument doc) dict


createShareDocumentDict : Types.DocumentDict -> Types.SharedDocumentDict
createShareDocumentDict documentDict =
    documentDict
        |> Dict.values
        |> List.foldl (\doc dict -> insert doc dict) Dict.empty
