module Diff.Change exposing (changes, changesP, reconcile, reconcileChange, reconcileChanges, reconcileList)

import Diff


type alias Change =
    Diff.Change String


changes : String -> String -> List (List (Diff.Change String))
changes a b =
    List.map2 Diff.diffLines (String.lines a) (String.lines b)


changesP : String -> String -> List (List (Diff.Change String))
changesP a b =
    let
        lines1 =
            String.lines a

        lines2 =
            String.lines b

        added =
            List.drop (List.length lines1) lines2
    in
    List.map2 Diff.diffLines (String.lines a) (String.lines b) ++ List.map (\item -> [ Diff.NoChange item ]) added


reconcileChange : Diff.Change String -> String -> String
reconcileChange change str =
    case change of
        Diff.NoChange _ ->
            str

        Diff.Removed x ->
            String.replace x "" str

        Diff.Added x ->
            str ++ x


reconcileChanges : List (Diff.Change String) -> String -> String
reconcileChanges changes_ str =
    List.foldl (\change str_ -> reconcileChange change str_) str changes_


reconcileList : List (List (Diff.Change String)) -> List String -> List String
reconcileList changesList stringList =
    List.map2 reconcileChanges changesList stringList


reconcile : List (List (Diff.Change String)) -> String -> String
reconcile changesList str =
    str |> String.lines |> reconcileList changesList |> String.join "\n"
