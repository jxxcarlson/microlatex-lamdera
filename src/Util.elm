module Util exposing
    ( Step(..)
    , andThenApply
    , apply
    , applyIf
    , compressWhitespace
    , delay
    , discardLines
    , insertInList
    , insertInListOrUpdate
    , liftToMaybe
    , loop
    )

import Duration
import Effect.Command exposing (Command)
import Effect.Process
import Effect.Task
import List.Extra
import Regex


apply : (a -> ( a, b )) -> a -> ( a, b )
apply f a =
    f a


andThenApply : (a -> ( a, b )) -> (List b -> b) -> ( a, b ) -> ( a, b )
andThenApply f batch ( a, b ) =
    let
        ( a2, b2 ) =
            f a
    in
    ( a2, batch [ b, b2 ] )


{-|

    Apply f to a if the flat is true, otherwise return a

-}
applyIf : Bool -> (a -> a) -> a -> a
applyIf flag f x =
    if flag then
        f x

    else
        x


liftToMaybe : (a -> b) -> (Maybe a -> Maybe b)
liftToMaybe f ma =
    case ma of
        Nothing ->
            Nothing

        Just a ->
            Just (f a)



-- LISTS


{-|

    > l1 = iou {id = "a", val = 1} []
    [{ id = "a", val = 1 }]

    > l2 = iou {id = "b", val = 1} l1
    [{ id = "b", val = 1 },{ id = "a", val = 1 }]

    > l3 = iou {id = "a", val = 3} l2
    [{ id = "b", val = 1 },{ id = "a", val = 3 }]

-}
insertInListOrUpdate : (a -> a -> Bool) -> a -> List a -> List a
insertInListOrUpdate equal a list =
    case List.head (List.filter (\b -> equal a b) list) of
        Nothing ->
            a :: list

        Just _ ->
            List.Extra.setIf (\x -> equal x a) a list


insertInList : a -> List a -> List a
insertInList a list =
    if List.Extra.notMember a list then
        a :: list

    else
        list


delay : Float -> msg -> Command restriction toMsg msg
delay time msg =
    Effect.Process.sleep (time |> Duration.milliseconds)
        |> Effect.Task.perform (\_ -> msg)


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


userReplace : String -> (Regex.Match -> String) -> String -> String
userReplace userRegex replacer string =
    case Regex.fromString userRegex of
        Nothing ->
            string

        Just regex ->
            Regex.replace regex replacer string


compressWhitespace : String -> String
compressWhitespace string =
    userReplace "\\s\\s+" (\_ -> " ") string
