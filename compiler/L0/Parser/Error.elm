module L0.Parser.Error exposing (ordinaryBlock)


ordinaryBlock : String -> List String -> List String -> Int -> String -> ( String, List String )
ordinaryBlock name args currentMessages lineNumber revisedContent =
    let
        lines =
            String.lines (String.trim revisedContent)

        n =
            List.length lines

        messages =
            currentMessages

        content =
            if n <= 1 then
                "[red •••? ]"

            else
                List.drop 1 lines |> String.join "\n"
    in
    ( content, messages )
