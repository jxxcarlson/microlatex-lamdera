module Compiler.Acc exposing
    ( Accumulator
    , init
    , transformAcccumulate
    , transformST
    )

import Compiler.ASTTools
import Compiler.Lambda as Lambda exposing (Lambda)
import Compiler.Util
import Compiler.Vector as Vector exposing (Vector)
import Config
import Dict exposing (Dict)
import Either exposing (Either(..))
import List.Extra
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Forest exposing (Forest)
import Parser.Language exposing (Language)
import Parser.MathMacro
import Tree exposing (Tree)


type alias Accumulator =
    { headingIndex : Vector
    , documentIndex : Vector
    , counter : Dict String Int
    , itemVector : Vector
    , numberedItemDict : Dict String { level : Int, index : Int }
    , numberedBlockNames : List String
    , environment : Dict String Lambda
    , inList : Bool
    , reference : Dict String { id : String, numRef : String }
    , terms : Dict String TermLoc
    , mathMacroDict : Parser.MathMacro.MathMacroDict
    }


getCounter : String -> Dict String Int -> Int
getCounter name dict =
    Dict.get name dict |> Maybe.withDefault 0


getCounterAsString : String -> Dict String Int -> String
getCounterAsString name dict =
    Dict.get name dict |> Maybe.map String.fromInt |> Maybe.withDefault ""


incrementCounter : String -> Dict String Int -> Dict String Int
incrementCounter name dict =
    Dict.insert name (getCounter name dict + 1) dict


transformST : Language -> Forest ExpressionBlock -> Forest ExpressionBlock
transformST lang ast =
    ast |> transformAcccumulate lang |> Tuple.second


transformAcccumulate : Language -> Forest ExpressionBlock -> ( Accumulator, Forest ExpressionBlock )
transformAcccumulate lang ast =
    List.foldl (\tree ( acc_, ast_ ) -> transformAccumulateTree lang tree acc_ |> mapper ast_) ( init 4, [] ) ast
        |> (\( acc_, ast_ ) -> ( acc_, List.reverse ast_ ))


init : Int -> Accumulator
init k =
    { headingIndex = Vector.init k
    , documentIndex = Vector.init k
    , inList = False
    , counter = Dict.empty
    , itemVector = Vector.init 4
    , numberedItemDict = Dict.empty
    , numberedBlockNames = [ "theorem", "lemma", "proposition", "corollary", "definition", "note", "remark", "problem", "equation", "aligned" ]
    , environment = Dict.empty
    , reference = Dict.empty
    , terms = Dict.empty
    , mathMacroDict = Dict.empty
    }


mapper ast_ ( acc_, tree_ ) =
    ( acc_, tree_ :: ast_ )


transformAccumulateTree : Language -> Tree ExpressionBlock -> Accumulator -> ( Accumulator, Tree ExpressionBlock )
transformAccumulateTree lang tree acc =
    let
        transformAccumulateBlock : Accumulator -> ExpressionBlock -> ( Accumulator, ExpressionBlock )
        transformAccumulateBlock =
            \acc_ block_ ->
                let
                    newAcc =
                        updateAccumulator lang block_ acc_
                in
                ( newAcc, transformBlock lang newAcc block_ )
    in
    Tree.mapAccumulate transformAccumulateBlock acc tree


transformBlock : Language -> Accumulator -> ExpressionBlock -> ExpressionBlock
transformBlock lang acc (ExpressionBlock block) =
    case ( block.name, block.args ) of
        ( Just "section", level :: _ ) ->
            ExpressionBlock
                { block | args = [ level, Vector.toString acc.headingIndex ] }

        ( Just "document", id :: level :: _ ) ->
            ExpressionBlock
                { block | args = [ id, level, Vector.toString acc.documentIndex ] }

        ( Just name_, _ ) ->
            -- Insert the numerical counter, e.g,, equation number, in the arg list of the block
            ExpressionBlock
                { block | args = insertInStringList (getCounterAsString (reduceName name_) acc.counter) block.args }

        _ ->
            expand acc.environment (ExpressionBlock block)


reduceName : String -> String
reduceName str =
    if List.member str [ "equation", "aligned" ] then
        "equation"

    else
        str


insertInStringList : String -> List String -> List String
insertInStringList str list =
    if str == "" then
        list

    else if List.Extra.notMember str list then
        str :: list

    else
        list


expand : Dict String Lambda -> ExpressionBlock -> ExpressionBlock
expand dict (ExpressionBlock block) =
    ExpressionBlock { block | content = Either.map (List.map (Lambda.expand dict)) block.content }


listData : Accumulator -> Maybe String -> ( Bool, Maybe Vector )
listData accumulator name =
    case ( accumulator.inList, name ) of
        ( False, Just "numbered" ) ->
            ( True, Just (Vector.init 4 |> Vector.increment 0) )

        ( False, Just "item" ) ->
            ( True, Just (Vector.init 4 |> Vector.increment 0) )

        ( _, Nothing ) ->
            -- Don't change state if there are anonymous blocks
            -- TODO: think about this, consistent with markdown semantics but not LaTeX
            -- TODO: however it does fix a numbering bug (see MicroLaTeX Visual Test)
            ( accumulator.inList, Nothing )

        ( False, _ ) ->
            ( False, Nothing )

        ( True, Just "numbered" ) ->
            ( True, Nothing )

        ( True, Just "item" ) ->
            ( True, Nothing )

        ( True, _ ) ->
            ( False, Nothing )


{-| Update the references dictionary: add a key-value pair where the
key is defined as in the examples \\lable{foo} or [label foo],
and where value is a record with an id and a "numerical" reference,
e.g, "2" or "2.3"
-}
updateReference : String -> String -> String -> Accumulator -> Accumulator
updateReference tag_ id_ numRef_ acc =
    if tag_ /= "" then
        { acc | reference = Dict.insert tag_ { id = id_, numRef = numRef_ } acc.reference }

    else
        acc


updateAccumulator : Language -> ExpressionBlock -> Accumulator -> Accumulator
updateAccumulator lang ((ExpressionBlock { name, indent, args, blockType, content, tag, id }) as block) accumulator =
    -- Update the accumulator for expression blocks with selected name
    case ( name, blockType ) of
        -- provide numbering for sections
        ( Just "section", OrdinaryBlock _ ) ->
            let
                level =
                    List.head args |> Maybe.withDefault "1"
            in
            updateWithOrdinarySectionBlock accumulator name content level id

        ( Just "document", OrdinaryBlock _ ) ->
            let
                level =
                    List.head args |> Maybe.withDefault "1"
            in
            updateWithOrdinaryDocumentBlock accumulator name content level id

        ( Just "bibitem", OrdinaryBlock _ ) ->
            updateBibItemBlock accumulator args content id

        ( Just name_, OrdinaryBlock _ ) ->
            -- TODO: tighten up
            updateWitOrdinaryBlock lang accumulator (Just name_) content args tag id indent

        -- provide for numbering of equations
        ( Just "mathmacros", VerbatimBlock [] ) ->
            updateWithMathMacros accumulator content

        ( Just _, VerbatimBlock _ ) ->
            -- TODO: tighten up
            updateWithVerbatimBlock accumulator name tag id

        ( Nothing, Paragraph ) ->
            updateWithParagraph accumulator Nothing content id

        _ ->
            -- TODO: take care of numberedItemIndex
            let
                ( inList, _ ) =
                    listData accumulator name
            in
            { accumulator | inList = inList }


updateWithOrdinarySectionBlock : Accumulator -> Maybe String -> Either String (List Expr) -> String -> String -> Accumulator
updateWithOrdinarySectionBlock accumulator name content level id =
    let
        ( inList, _ ) =
            listData accumulator name

        titleWords =
            case content of
                Left str ->
                    [ Compiler.Util.compressWhitespace str ]

                Right expr ->
                    List.map Compiler.ASTTools.getText expr |> Maybe.Extra.values |> List.map Compiler.Util.compressWhitespace

        sectionTag =
            -- TODO: the below is a bad solution
            titleWords |> List.map (String.toLower >> String.replace " " "-") |> String.join ""

        headingIndex =
            Vector.increment (String.toInt level |> Maybe.withDefault 0) accumulator.headingIndex
    in
    -- TODO: take care of numberedItemIndex = 0 here and elsewhere
    { accumulator | inList = inList, headingIndex = headingIndex } |> updateReference sectionTag id (Vector.toString headingIndex)


updateWithOrdinaryDocumentBlock : Accumulator -> Maybe String -> Either String (List Expr) -> String -> String -> Accumulator
updateWithOrdinaryDocumentBlock accumulator name content level id =
    let
        ( inList, _ ) =
            listData accumulator name

        title =
            case content of
                Left str ->
                    str

                Right expr ->
                    List.map Compiler.ASTTools.getText expr |> Maybe.Extra.values |> String.join " "

        sectionTag =
            title |> String.toLower |> String.replace " " "-"

        documentIndex =
            --Vector.increment (String.toInt level |> Maybe.withDefault 0 |> (\x -> x - 1)) accumulator.headingIndex
            Vector.increment (String.toInt level |> Maybe.withDefault 0) accumulator.documentIndex
    in
    -- TODO: take care of numberedItemIndex = 0 here and elsewhere
    { accumulator | inList = inList, documentIndex = documentIndex } |> updateReference sectionTag id (Vector.toString documentIndex)


updateBibItemBlock accumulator args content id =
    case List.head args of
        Nothing ->
            accumulator

        Just label ->
            { accumulator | reference = Dict.insert label { id = id, numRef = "_irrelevant_" } accumulator.reference }


updateWitOrdinaryBlock : a -> Accumulator -> Maybe String -> Either b (List Expr) -> e -> String -> String -> Int -> Accumulator
updateWitOrdinaryBlock lang accumulator name content args_ tag id indent =
    let
        ( inList, initialNumberedVector ) =
            listData accumulator name
    in
    case name of
        Just "defs" ->
            -- incorporate runtime macro definitions
            case content of
                Left _ ->
                    accumulator

                Right exprs ->
                    { accumulator | inList = inList, environment = List.foldl (\lambda dict -> Lambda.insert (Lambda.extract lambda) dict) accumulator.environment exprs }

        Just "setcounter" ->
            case content of
                Left _ ->
                    accumulator

                Right exprs ->
                    let
                        ctr =
                            case exprs of
                                [ Text val _ ] ->
                                    String.toInt val |> Maybe.withDefault 1

                                _ ->
                                    1

                        headingIndex =
                            Vector.init accumulator.headingIndex.size |> Vector.set 0 (ctr - 1)
                    in
                    { accumulator | headingIndex = headingIndex }

        Just "numbered" ->
            let
                level =
                    indent // Config.indentationQuantum

                itemVector =
                    case initialNumberedVector of
                        Just v ->
                            v

                        Nothing ->
                            Vector.increment level accumulator.itemVector

                index =
                    Vector.get level itemVector

                numberedItemDict =
                    Dict.insert id { level = level, index = index } accumulator.numberedItemDict
            in
            { accumulator | inList = inList, itemVector = itemVector, numberedItemDict = numberedItemDict }
                |> updateReference tag id (String.fromInt (Vector.get level itemVector))

        Just "item" ->
            let
                level =
                    indent // Config.indentationQuantum

                itemVector =
                    case initialNumberedVector of
                        Just v ->
                            v

                        Nothing ->
                            Vector.increment level accumulator.itemVector

                numberedItemDict =
                    Dict.insert id { level = level, index = Vector.get level itemVector } accumulator.numberedItemDict
            in
            { accumulator | inList = inList, itemVector = itemVector, numberedItemDict = numberedItemDict }
                |> updateReference tag id (String.fromInt (Vector.get level itemVector))

        Just name_ ->
            let
                newCounter =
                    if List.member name_ accumulator.numberedBlockNames then
                        incrementCounter name_ accumulator.counter

                    else
                        accumulator.counter
            in
            { accumulator | counter = newCounter }

        --  |> updateReference tag id (String.fromInt (Vector.get level itemVector))
        _ ->
            accumulator


updateWithMathMacros accumulator content =
    let
        definitions =
            case content of
                Left str ->
                    str
                        |> String.replace "\\begin{mathmacros}" ""
                        |> String.replace "\\end{mathmacros}" ""
                        |> String.replace "end" ""
                        |> String.trim

                _ ->
                    ""

        mathMacroDict =
            Parser.MathMacro.makeMacroDict (String.trim definitions)
    in
    { accumulator | mathMacroDict = mathMacroDict }


updateWithVerbatimBlock accumulator name_ tag id =
    let
        ( inList, _ ) =
            listData accumulator name_

        name =
            Maybe.withDefault "---" name_

        -- Increment the appropriate counter, e.g., "equation"
        newCounter =
            if List.member name accumulator.numberedBlockNames then
                incrementCounter (reduceName name) accumulator.counter

            else
                accumulator.counter
    in
    { accumulator | inList = inList, counter = newCounter }
        -- Update the references dictionary
        |> updateReference tag id (getCounter (reduceName name) newCounter |> String.fromInt)


updateWithParagraph accumulator name content id =
    let
        ( inList, _ ) =
            listData accumulator name
    in
    { accumulator | inList = inList, terms = addTermsFromContent id content accumulator.terms }


type alias TermLoc =
    { begin : Int, end : Int, id : String }


type alias TermData =
    { term : String, loc : TermLoc }


getTerms : String -> Either String (List Expr) -> List TermData
getTerms id content_ =
    case content_ of
        Right expressionList ->
            Compiler.ASTTools.filterExpressionsOnName "term" expressionList
                |> List.map (extract id)
                |> Maybe.Extra.values

        -- |> List.map Compiler.ASTTools.getText
        Left _ ->
            []



-- TERMS: [Expr "term" [Text "group" { begin = 19, end = 23, index = 4 }] { begin = 13, end = 13, index = 1 }]


extract : String -> Expr -> Maybe TermData
extract id expr =
    case expr of
        Expr "term" [ Text name { begin, end } ] _ ->
            Just { term = name, loc = { begin = begin, end = end, id = id } }

        _ ->
            Nothing


addTerm : TermData -> Dict String TermLoc -> Dict String TermLoc
addTerm termData dict =
    Dict.insert termData.term termData.loc dict


addTerms : List TermData -> Dict String TermLoc -> Dict String TermLoc
addTerms termDataList dict =
    List.foldl addTerm dict termDataList


addTermsFromContent : String -> Either String (List Expr) -> Dict String TermLoc -> Dict String TermLoc
addTermsFromContent id content dict =
    addTerms (getTerms id content) dict
