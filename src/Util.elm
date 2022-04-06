module Util exposing
    ( batch
    , currentUsername
    , delay
    , insertInList
    , insertInListViaTitle
    , updateDocumentInList
    )

import Document exposing (Document)
import List.Extra
import Process
import Task
import User


currentUsername : Maybe User.User -> String
currentUsername currentUser =
    Maybe.map .username currentUser |> Maybe.withDefault "(nobody)"


insertInList : a -> List a -> List a
insertInList a list =
    if List.Extra.notMember a list then
        a :: list

    else
        list


batch =
    \( m, cmds ) -> ( m, Cmd.batch cmds )



-- LISTS


{-| -}
updateDocumentInList : Document -> List Document -> List Document
updateDocumentInList doc list =
    List.Extra.setIf (\d -> d.id == doc.id) doc list


insertInListViaTitle : Document -> List Document -> List Document
insertInListViaTitle doc list =
    if List.Extra.notMember doc.title (List.map .title list) then
        doc :: list

    else
        list


delay : Float -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)
