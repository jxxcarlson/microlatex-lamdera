module Util exposing
    ( currentUsername
    , delay
    , documentIsMine
    , insertInListOrUpdate
    , liftToMaybe
    , updateDocumentInList
    )

import Document exposing (Document)
import List.Extra
import Process
import Task
import User


liftToMaybe : (a -> b) -> (Maybe a -> Maybe b)
liftToMaybe f ma =
    case ma of
        Nothing ->
            Nothing

        Just a ->
            Just (f a)


currentUsername : Maybe User.User -> String
currentUsername currentUser =
    Maybe.map .username currentUser |> Maybe.withDefault "(nobody)"


documentIsMine : Maybe Document -> Maybe User.User -> Bool
documentIsMine maybeDoc maybeUser =
    case ( maybeDoc, maybeUser ) of
        ( Nothing, _ ) ->
            False

        ( _, Nothing ) ->
            False

        ( Just doc, Just user ) ->
            doc.author == Just user.username


batch =
    \( m, cmds ) -> ( m, Cmd.batch cmds )



-- LISTS


{-| -}
updateDocumentInList : Document -> List Document -> List Document
updateDocumentInList doc list =
    List.Extra.setIf (\d -> d.id == doc.id) doc list


insertInListOrUpdate : Document -> List Document -> List Document
insertInListOrUpdate doc list =
    if List.Extra.notMember doc list then
        doc :: list

    else
        updateDocumentInList doc list


insertInList : a -> List a -> List a
insertInList a list =
    if List.Extra.notMember a list then
        a :: list

    else
        list


delay : Float -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)
