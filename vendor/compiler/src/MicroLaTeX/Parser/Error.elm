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
            if List.member name [ "item", "numbered" ] then
                if n <= 1 then
                    "\n\\red{•••}"

                else
                    List.drop 1 lines |> String.join "\n"
                -- else if String.left 1 lastLine ==

            else if n <= 1 then
                "\n•••\\vskip{1}\n\\red{\\bs{end} •••}"

            else if lastLine == "\\" then
                sliceList 1 (n - 2) lines
                    |> String.join "\n"
                    |> (\s -> s ++ "\n\\vskip{1}\n\\red{\\bs{end} •••}")

            else if lastLine == endString then
                sliceList 1 (n - 2) lines |> String.join "\n"

            else if String.contains "\\end" lastLine then
                sliceList 1 (n - 2) lines |> String.join "\n" |> (\x -> x ++ "\n\\vskip{1}\n\\red{\\bs{end} •••}")

            else if String.left 1 lastLine == "\\" then
                sliceList 1 (n - 2) lines |> String.join "\n" |> (\x -> x ++ "\n\\vskip{1}\n\\red{\\bs{??}}\n\\vskip{1}\n\\red{\\bs{end} •••}")

            else
                sliceList 1 (n - 1) lines |> String.join "\n" |> (\x -> x ++ "\n\\vskip{1}\n\\red{\\bs{end} •••}")
    in
    ( content, messages )


{-|

    > sliceList 1 2 [0, 1, 2, 3]
    [1,2]

-}
sliceList : Int -> Int -> List a -> List a
sliceList a b list =
    list |> List.take (b + 1) |> List.drop a
