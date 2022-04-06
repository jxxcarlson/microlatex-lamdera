module SharedDocument exposing (createShareDocumentDict, isSharedToMe)

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


isSharedToMe : String -> Document.Share -> Bool
isSharedToMe username share =
    case share of
        Document.NotShared ->
            False

        Document.ShareWith { readers, editors } ->
            List.member username readers || List.member username editors


insert : Document.Document -> Types.SharedDocumentDict -> Types.SharedDocumentDict
insert doc dict =
    case doc.share of
        Document.NotShared ->
            dict

        Document.ShareWith _ ->
            Dict.insert doc.id (getSharedDocument doc) dict


createShareDocumentDict : Types.DocumentDict -> Types.SharedDocumentDict
createShareDocumentDict documentDict =
    documentDict
        |> Dict.values
        |> List.foldl (\doc dict -> insert doc dict) Dict.empty
