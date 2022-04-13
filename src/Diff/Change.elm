module Diff.Change exposing (reconcileList, reconcileMany, reconcileOne)

import Diff


type alias Change =
    Diff.Change String


reconcileOne : Diff.Change String -> String -> String
reconcileOne change str =
    case change of
        Diff.NoChange _ ->
            str

        Diff.Removed x ->
            String.replace x "" str

        Diff.Added x ->
            str ++ x


reconcileMany : List (Diff.Change String) -> String -> String
reconcileMany changes str =
    List.foldl (\change str_ -> reconcileOne change str_) str changes


reconcileList : List (List (Diff.Change String)) -> List String -> List String
reconcileList changesList stringList =
    List.map2 reconcileMany changesList stringList
