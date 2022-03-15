module XMarkdown.Transform exposing (transform)

import Dict exposing (Dict)
import Parser.Line exposing (PrimitiveBlockType(..))
import Parser.MathMacro exposing (MathExpression(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)


pseudoBlockNames =
    [ "item", "numbered", "bibitem", "abstract" ]


pseudoBlockNamesWithArgs =
    [ "setcounter", "contents" ]


pseudoBlockNamesWithContent =
    [ "title", "section", "subsection", "subsubsection", "subheading" ]


sectionDict : Dict String String
sectionDict =
    Dict.fromList
        [ ( "section", "1" )
        , ( "subsection", "2" )
        , ( "subsubsection", "3" )
        , ( "subheading", "4" )
        ]


transform : PrimitiveBlock -> PrimitiveBlock
transform block =
    (let
        normalizedContent =
            block.content |> Debug.log "IN" |> List.map (String.dropLeft block.indent) |> normalize |> Debug.log "normalize (OUT)"
     in
     case normalizedContent of
        firstLine :: rest_ ->
            if String.left 1 firstLine == "#" then
                handleTitle block firstLine rest_

            else if String.left 2 firstLine == "$$" then
                handleMath block rest_

            else if String.left 3 firstLine == "```" then
                handleVerbatim block rest_

            else
                block

        _ ->
            block
    )
        |> Debug.log "TRANSFORM"


handleVerbatim : PrimitiveBlock -> List String -> PrimitiveBlock
handleVerbatim block rest =
    { block | name = Just "code", named = True, blockType = PBVerbatim }


handleMath : PrimitiveBlock -> List String -> PrimitiveBlock
handleMath block rest =
    { block | name = Just "math", named = True, blockType = PBVerbatim, content = List.filter (\item -> item /= "") block.content }


handleTitle : PrimitiveBlock -> String -> List String -> PrimitiveBlock
handleTitle block firstLine rest =
    let
        words =
            String.split " " firstLine
    in
    case Maybe.map String.length (List.head words) of
        Nothing ->
            block

        Just 0 ->
            block

        Just 1 ->
            { block | args = [], blockType = PBOrdinary, name = Just "title", content = [ "| title", String.join " " (List.drop 1 words) ] }

        Just n ->
            let
                first =
                    "| section " ++ String.fromInt n

                level =
                    String.fromInt n
            in
            { block | args = [ level ], blockType = PBOrdinary, name = Just "section", content = [ first, String.join " " (List.drop 1 words) ] }



-- RESIDUE


handlePseudoblock block name rest_ macroExpr =
    case macroExpr of
        Nothing ->
            { block | content = ("| " ++ name) :: rest_, name = Just name, blockType = PBOrdinary }

        Just ((Macro macroName args) as macro) ->
            { block
                | content = ("| " ++ macroName) :: rest_
                , name = Just name
                , args = List.map Parser.MathMacro.getArgs args |> List.concat
                , blockType = PBOrdinary
            }

        _ ->
            { block | content = ("| " ++ name) :: rest_, name = Just name, blockType = PBOrdinary }


handlePseudoBlockWithContent block name name_ macroExpr =
    case macroExpr of
        Nothing ->
            block

        Just ((Macro macroName args) as macro) ->
            let
                realArgs =
                    List.map Parser.MathMacro.getArgs args |> List.concat

                mainContent =
                    List.map Parser.MathMacro.getArgs args |> List.concat
            in
            case Dict.get macroName sectionDict of
                Nothing ->
                    { block | content = ("| " ++ macroName) :: mainContent, name = Just name, args = realArgs, blockType = PBOrdinary }

                Just val ->
                    { block | content = ("| section " ++ val) :: mainContent, args = val :: [], name = Just "section", blockType = PBOrdinary }

        _ ->
            block


handlePseudoblockWithArgs block name rest_ macroExpr =
    case macroExpr of
        Nothing ->
            block

        Just ((Macro macroName args) as macro) ->
            { block | content = ("| " ++ macroName) :: rest_, name = Just name, args = List.map Parser.MathMacro.getArgs args |> List.concat, blockType = PBOrdinary }

        _ ->
            block


normalize : List String -> List String
normalize list =
    case list of
        "" :: rest ->
            rest

        _ ->
            list
