module MicroLaTeX.Parser.Error exposing (..)

import Parser.Common
import Parser.Helpers


ordinaryBlock : String -> List String -> List String -> Int -> String -> ( String, List String )
ordinaryBlock name args currentMessages lineNumber revisedContent =
    let
        lines =
            String.lines (String.trim revisedContent)

        n =
            List.length lines

        lastLine =
            List.drop (n - 1) lines |> String.join ""

        messages =
            currentMessages

        endString =
            "\\end{" ++ name ++ "}"

        content =
            if n <= 1 then
                "\\red{ •••?}"

            else if List.member name [ "item", "numbered" ] then
                List.drop 1 lines |> String.join "\n"

            else if lastLine == "\\" then
                sliceList 1 (n - 1) lines
                    |> String.join "\n"
                    |> (\s -> s ++ "\n\\red{\\•••?}")

            else if lastLine == endString then
                sliceList 1 (n - 2) lines |> String.join "\n"

            else if lastLine /= endString then
                -- sliceList 1 (n - 1) lines |> String.join "\n" |> (\x -> x ++ "\n\\vskip{1}\n\\red{••• end?}")
                sliceList 1 (n - 2) lines |> String.join "\n" |> (\x -> x ++ "\n\\vskip{1}\n\\red{••• ?}")

            else
                sliceList 1 (n - 2) lines |> String.join "\n"
    in
    ( content, messages )


{-|

    > sliceList 1 2 [0, 1, 2, 3]
    [1,2]

-}
sliceList : Int -> Int -> List a -> List a
sliceList a b list =
    list |> List.take (b + 1) |> List.drop a
