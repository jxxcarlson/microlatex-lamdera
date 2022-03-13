module Parser.PrimitiveTransform exposing (transform)

import Dict exposing (Dict)
import Parser.Language exposing (Language(..))
import Parser.Line exposing (PrimitiveBlockType(..))
import Parser.MathMacro exposing (MathExpression(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)


transform : Language -> PrimitiveBlock -> PrimitiveBlock
transform lang block =
    case lang of
        L0Lang ->
            block

        MicroLaTeXLang ->
            transformMiniLaTeX block


pseudoBlockNames =
    [ "item", "numbered" ]


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


transformMiniLaTeX : PrimitiveBlock -> PrimitiveBlock
transformMiniLaTeX block =
    let
        normalizedContent =
            block.content |> List.map (String.dropLeft block.indent) |> normalize |> Debug.log "NORMALIZED"
    in
    case normalizedContent of
        name_ :: rest_ ->
            let
                name =
                    (if String.left 1 name_ == "\\" then
                        String.dropLeft 1 name_ |> String.split "{" |> List.head |> Maybe.withDefault "---"

                     else
                        name_
                    )
                        |> Debug.log "NAME"
            in
            if List.member name pseudoBlockNames then
                { block | content = ("| " ++ name) :: rest_, name = Just name, blockType = PBOrdinary } |> Debug.log "PSEUDO"

            else if List.member name pseudoBlockNamesWithContent then
                let
                    _ =
                        Debug.log "VALID pseudoBlockNameWithContent" name
                in
                case Parser.MathMacro.parseOne name_ of
                    Nothing ->
                        block

                    Just ((Macro macroName args) as macro) ->
                        let
                            _ =
                                Debug.log "MACRO" macro

                            mainContent =
                                List.map Parser.MathMacro.getArgs args |> List.concat
                        in
                        case Dict.get macroName sectionDict of
                            Nothing ->
                                { block | content = ("| " ++ macroName) :: mainContent, name = Just name, blockType = PBOrdinary }

                            Just val ->
                                { block | content = ("| section " ++ val) :: mainContent, args = val :: [], name = Just "section", blockType = PBOrdinary }

                    _ ->
                        block

            else if List.member name pseudoBlockNamesWithArgs then
                case Parser.MathMacro.parseOne name_ of
                    Nothing ->
                        block

                    Just ((Macro macroName args) as macro) ->
                        { block | content = ("| " ++ macroName) :: [], name = Just name, args = List.map Parser.MathMacro.getArgs args |> List.concat, blockType = PBOrdinary }

                    _ ->
                        block

            else
                block

        _ ->
            block


normalize : List String -> List String
normalize list =
    case list of
        "" :: rest ->
            rest

        _ ->
            list
