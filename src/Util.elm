module Util exposing
    ( Step(..)
    , currentUserId
    , currentUsername
    , delay
    , discardLines
    , insertInList
    , insertInListOrUpdate
    , liftToMaybe
    , loop
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


currentUserId : Maybe User.User -> String
currentUserId currentUser =
    Maybe.map .id currentUser |> Maybe.withDefault "----"


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


type alias DiscardLinesState =
    { input : List String }


discardLines : (String -> Bool) -> List String -> List String
discardLines predicate lines =
    loop { input = lines } (discardLinesNextStep predicate)


{-| Discard lines until the predicate is satisfied; discard that line, then return the rest
-}
discardLinesNextStep : (String -> Bool) -> DiscardLinesState -> Step DiscardLinesState (List String)
discardLinesNextStep predicate state =
    case List.head state.input of
        Nothing ->
            Done state.input

        Just line ->
            if predicate line then
                Done (List.drop 1 state.input)

            else
                Loop { state | input = List.drop 1 state.input }


type Step state a
    = Loop state
    | Done a


loop : state -> (state -> Step state a) -> a
loop s nextState_ =
    case nextState_ s of
        Loop s_ ->
            loop s_ nextState_

        Done b ->
            b
