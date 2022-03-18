module Parser.TransformLaTeX exposing
    ( indentStrings
    , transformToL0
    , transformToL0Aux
    )

import Parser.MathMacro exposing (MathExpression(..))



-- TRANSFORMS


type alias IndentationData =
    { indent : Int, input : List String, output : List String }


transformToL0 : List String -> List String
transformToL0 strings =
    strings |> indentStrings |> transformToL0Aux


indentStrings : List String -> List String
indentStrings strings =
    indentAux { indent = -1, input = strings, output = [] } |> .output |> List.reverse


indentAux : IndentationData -> IndentationData
indentAux ({ indent, input, output } as data) =
    case input of
        [] ->
            data

        first :: rest ->
            let
                newIndent =
                    if isBegin first then
                        indent + 1

                    else if isEnd first then
                        indent - 1

                    else
                        indent

                newOutput =
                    if isEnd first then
                        indentString indent first :: output

                    else
                        indentString newIndent first :: output
            in
            indentAux { data | output = newOutput, input = rest, indent = newIndent }


indentString : Int -> String -> String
indentString k str =
    String.repeat (2 * k) " " ++ str


transformToL0Aux : List String -> List String
transformToL0Aux strings =
    let
        mapper str =
            let
                bareString =
                    String.trimLeft str
            in
            if isBegin bareString then
                case Parser.MathMacro.parseOne bareString of
                    Just (Macro "begin" [ MathList [ MathText blockName ] ]) ->
                        String.replace ("\\begin{" ++ blockName ++ "}") ("| " ++ blockName) str

                    _ ->
                        ""

            else if isEnd bareString then
                "(delete)"

            else
                str
    in
    strings |> List.map mapper |> List.filter (\s -> s /= "(delete)")


isBegin : String -> Bool
isBegin str =
    String.left 6 (String.trimLeft str) == "\\begin"


isEnd : String -> Bool
isEnd str =
    String.left 4 (String.trimLeft str) == "\\end"
