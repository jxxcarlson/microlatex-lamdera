module Compiler.Acc exposing
    ( Accumulator
    , init
    , make
    , transformST
    )

import Compiler.ASTTools
import Compiler.Lambda as Lambda exposing (Lambda)
import Compiler.Vector as Vector exposing (Vector)
import Dict exposing (Dict)
import Either exposing (Either(..))
import L0.Transform
import List.Extra
import Maybe.Extra
import MicroLaTeX.Compiler.LaTeX
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Language exposing (Language(..))
import Parser.MathMacro
import Tree exposing (Tree)


type alias Accumulator =
    { headingIndex : Vector
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


transformST : Language -> List (Tree ExpressionBlock) -> List (Tree ExpressionBlock)
transformST lang ast =
    ast |> make lang |> Tuple.second


make : Language -> List (Tree ExpressionBlock) -> ( Accumulator, List (Tree ExpressionBlock) )
make lang ast =
    List.foldl (\tree ( acc_, ast_ ) -> transformAccumulateTree lang tree acc_ |> mapper ast_) ( init 4, [] ) ast
        |> (\( acc_, ast_ ) -> ( acc_, List.reverse ast_ ))


init : Int -> Accumulator
init k =
    { headingIndex = Vector.init k
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
        transformer : Accumulator -> ExpressionBlock -> ( Accumulator, ExpressionBlock )
        transformer =
            \acc_ block__ ->
                let
                    block_ =
                        case lang of
                            MicroLaTeXLang ->
                                MicroLaTeX.Compiler.LaTeX.transform block__

                            L0Lang ->
                                L0.Transform.transform block__

                    newAcc =
                        updateAccumulator lang block_ acc_
                in
                ( newAcc, transformBlock lang newAcc block_ )
    in
    Tree.mapAccumulate transformer acc tree


transformBlock : Language -> Accumulator -> ExpressionBlock -> ExpressionBlock
transformBlock lang acc (ExpressionBlock block) =
    case block.blockType of
        OrdinaryBlock [ "section", level ] ->
            ExpressionBlock
                { block | args = [ level, Vector.toString acc.headingIndex ] }

        OrdinaryBlock args ->
            case List.head args of
                -- TODO: review this code
                Just name ->
                    ExpressionBlock
                        { block | args = insertInList (getCounterAsString name acc.counter) block.args }

                _ ->
                    ExpressionBlock block

        VerbatimBlock [ name ] ->
            ExpressionBlock
                { block | args = insertInList (getCounterAsString name acc.counter) block.args }

        _ ->
            expand acc.environment (ExpressionBlock block)


insertInList : a -> List a -> List a
insertInList a list =
    if List.Extra.notMember a list then
        a :: list

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

        ( False, _ ) ->
            ( False, Nothing )

        ( True, Just "numbered" ) ->
            ( True, Nothing )

        ( True, _ ) ->
            ( False, Nothing )


updateReference : String -> String -> String -> Accumulator -> Accumulator
updateReference tag_ id_ numRef_ acc =
    if tag_ /= "" then
        { acc | reference = Dict.insert tag_ { id = id_, numRef = numRef_ } acc.reference }

    else
        acc


updateWithOrdinarySectionBlock : Accumulator -> Maybe String -> Either String (List Expr) -> String -> String -> Accumulator
updateWithOrdinarySectionBlock accumulator name content level id =
    let
        ( inList, initialNumberedVector ) =
            listData accumulator name

        title =
            case content of
                Left str ->
                    str

                Right expr ->
                    List.map Compiler.ASTTools.getText expr |> Maybe.Extra.values |> String.join " "

        sectionTag =
            title |> String.toLower |> String.replace " " "-"

        headingIndex =
            Vector.increment (String.toInt level |> Maybe.withDefault 0 |> (\x -> x - 1)) accumulator.headingIndex
    in
    -- TODO: take care of numberedItemIndex = 0 here and elsewhere
    { accumulator | inList = inList, headingIndex = headingIndex } |> updateReference sectionTag id (Vector.toString headingIndex)


updateWitOrdinaryBlock lang accumulator name content args_ tag id indent =
    let
        ( inList, initialNumberedVector ) =
            listData accumulator name
    in
    case List.head args_ of
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
                    case lang of
                        MicroLaTeXLang ->
                            indent // 2

                        L0Lang ->
                            indent // 2 - 1

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

        _ ->
            accumulator


updateAccumulator : Language -> ExpressionBlock -> Accumulator -> Accumulator
updateAccumulator lang ((ExpressionBlock { name, indent, args, blockType, content, tag, id }) as block) accumulator =
    case blockType of
        -- provide numbering for sections
        OrdinaryBlock [ "section", level ] ->
            updateWithOrdinarySectionBlock accumulator name content level id

        OrdinaryBlock args_ ->
            updateWitOrdinaryBlock lang accumulator name content args_ tag id indent

        -- provide for numbering of equations
        VerbatimBlock [ "mathmacros" ] ->
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

        VerbatimBlock [ name_ ] ->
            let
                ( inList, initialNumberedVector ) =
                    listData accumulator name

                newCounter =
                    if List.member name_ accumulator.numberedBlockNames then
                        incrementCounter name_ accumulator.counter

                    else
                        accumulator.counter
            in
            { accumulator | inList = inList, counter = newCounter }
                |> updateReference tag id (getCounter name_ newCounter |> String.fromInt)

        Paragraph ->
            let
                ( inList, initialNumberedVector ) =
                    listData accumulator name
            in
            { accumulator | inList = inList, terms = addTermsFromContent id content accumulator.terms }

        _ ->
            -- TODO: take care of numberedItemIndex
            let
                ( inList, initialNumberedVector ) =
                    listData accumulator name
            in
            { accumulator | inList = inList }


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
