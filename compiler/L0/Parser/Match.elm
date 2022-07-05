module L0.Parser.Match exposing (deleteAt, match, reducible, splitAt)

import L0.Parser.Symbol exposing (Symbol(..), value)
import Parser.Helpers exposing (Step(..), loop)


reducible : List Symbol -> Bool
reducible symbols_ =
    let
        symbols =
            List.filter (\sym -> sym /= WS) symbols_
    in
    case symbols of
        M :: rest ->
            List.head (List.reverse rest) == Just M

        C :: rest ->
            List.head (List.reverse rest) == Just C

        L :: ST :: rest ->
            case List.head (List.reverse rest) of
                Just R ->
                    reducibleList (dropLast rest)

                _ ->
                    False

        _ ->
            False


dropLast : List a -> List a
dropLast list =
    let
        n =
            List.length list
    in
    List.take (n - 1) list


reducibleList : List Symbol -> Bool
reducibleList symbols =
    case symbols of
        [] ->
            True

        L :: _ ->
            case match symbols of
                Nothing ->
                    False

                Just k ->
                    let
                        ( a, b ) =
                            splitAt (k + 1) symbols
                    in
                    if reducible a then
                        reducibleList b

                    else
                        False

        ST :: rest ->
            reducibleList rest

        _ ->
            False


{-|

> deleteAt 1 [0, 1, 2]

     [0,2] : List number

-}
deleteAt : Int -> List a -> List a
deleteAt k list =
    List.take k list ++ List.drop (k + 1) list


{-|

    > splitAt 2 [0, 1, 2, 3, 4]
      ([0,1],[3,4])

-}
splitAt : Int -> List a -> ( List a, List a )
splitAt k list =
    ( List.take k list, List.drop (k + 0) list )


type alias State =
    { symbols : List Symbol, index : Int, brackets : Int }


match : List Symbol -> Maybe Int
match symbols =
    case List.head symbols of
        Nothing ->
            Nothing

        Just symbol ->
            if value symbol < 0 then
                Nothing

            else
                loop { symbols = List.drop 1 symbols, index = 1, brackets = value symbol } nextStep


nextStep : State -> Step State (Maybe Int)
nextStep state =
    case List.head state.symbols of
        Nothing ->
            Done Nothing

        Just sym ->
            let
                brackets =
                    state.brackets + value sym
            in
            if brackets < 0 then
                Done Nothing

            else if brackets == 0 then
                Done (Just state.index)

            else
                Loop { symbols = List.drop 1 state.symbols, index = state.index + 1, brackets = brackets }
