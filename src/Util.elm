module Util exposing (batch, delay, insertInList, insertInListViaTitle)

import Document exposing (Document)
import List.Extra
import Process
import Task


insertInList : a -> List a -> List a
insertInList a list =
    if List.Extra.notMember a list then
        a :: list

    else
        list


batch =
    \( m, cmds ) -> ( m, Cmd.batch cmds )


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
