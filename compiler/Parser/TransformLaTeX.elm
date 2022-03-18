module Parser.TransformLaTeX exposing
    ( indentStrings
    , transformToL0
    , transformToL0Aux
    )

import Parser.MathMacro exposing (MathExpression(..))



-- TRANSFORMS


type alias IndentationData =
    { indent : Int, input : List String, output : List String, blockNameStack : List String }


transformToL0 : List String -> List String
transformToL0 strings =
    strings |> indentStrings |> transformToL0Aux


indentStrings : List String -> List String
indentStrings strings =
    indentAux { indent = -1, input = strings, output = [], blockNameStack = [] } |> .output |> List.reverse


indentAux : IndentationData -> IndentationData
indentAux ({ indent, input, output, blockNameStack } as data) =
    case input of
        [] ->
            data

        first :: rest ->
            let
                ( newIndent, blockNameStack_, error ) =
                    case ( blockBegin first, blockEnd first ) of
                        ( Just blockName, Nothing ) ->
                            ( indent + 1, blockName :: blockNameStack, NoError )

                        ( Nothing, Just blockName ) ->
                            case List.head blockNameStack of
                                Nothing ->
                                    ( indent - 1, List.drop 1 blockNameStack, MissingEndBlock blockName )

                                Just blockNameTop ->
                                    if blockName == blockNameTop then
                                        ( indent - 1, List.drop 1 blockNameStack, NoError )

                                    else
                                        ( indent - 1, blockNameStack, MisMatchedEndBlock blockName blockNameTop )

                        _ ->
                            case ( first, blockNameStack ) of
                                ( "", blockName :: rest_ ) ->
                                    ( indent, rest_, MissingEndBlock blockName )

                                _ ->
                                    ( indent, blockNameStack, NoError )

                newOutput =
                    if isEnd first then
                        indentString indent first :: output

                    else
                        indentString newIndent first :: output
            in
            case error of
                NoError ->
                    indentAux { data | output = newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }

                MissingEndBlock blockName ->
                    indentAux { data | output = ("missing end block: " ++ blockName) :: newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }

                MisMatchedEndBlock b1 b2 ->
                    indentAux { data | output = ("mismatched end blocks: " ++ b1 ++ ", " ++ b2) :: newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }


type LaTeXError
    = NoError
    | MissingEndBlock String
    | MisMatchedEndBlock String String


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


blockBegin : String -> Maybe String
blockBegin str =
    case Parser.MathMacro.parseOne str of
        Just (Macro "begin" [ MathList [ MathText blockName ] ]) ->
            Just blockName

        _ ->
            Nothing


blockEnd : String -> Maybe String
blockEnd str =
    case Parser.MathMacro.parseOne str of
        Just (Macro "end" [ MathList [ MathText blockName ] ]) ->
            Just blockName

        _ ->
            Nothing


isBegin : String -> Bool
isBegin str =
    String.left 6 (String.trimLeft str) == "\\begin"


isEnd : String -> Bool
isEnd str =
    String.left 4 (String.trimLeft str) == "\\end"
