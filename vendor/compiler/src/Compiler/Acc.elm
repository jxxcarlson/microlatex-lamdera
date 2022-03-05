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
import Tree exposing (Tree)


type alias Accumulator =
    { headingIndex : Vector
    , counter : Dict String Int
    , numberedBlockNames : List String
    , environment : Dict String Lambda
    , inList : Bool
    , reference : Dict String { id : String, numRef : String }
    , terms : Dict String TermLoc
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


transformST : Language -> List (Tree (ExpressionBlock Expr)) -> List (Tree (ExpressionBlock Expr))
transformST lang ast =
    ast |> make lang |> Tuple.second


make : Language -> List (Tree (ExpressionBlock Expr)) -> ( Accumulator, List (Tree (ExpressionBlock Expr)) )
make lang ast =
    List.foldl (\tree ( acc_, ast_ ) -> transformAccumulateTree lang tree acc_ |> mapper ast_) ( init 4, [] ) ast
        |> (\( acc_, ast_ ) -> ( acc_, List.reverse ast_ ))


init : Int -> Accumulator
init k =
    { headingIndex = Vector.init k
    , inList = False
    , counter = Dict.empty
    , numberedBlockNames = [ "theorem", "lemma", "proposition", "corollary", "definition", "note", "remark", "problem", "equation", "aligned" ]
    , environment = Dict.empty
    , reference = Dict.empty
    , terms = Dict.empty
    }


mapper ast_ ( acc_, tree_ ) =
    ( acc_, tree_ :: ast_ )


transformAccumulateTree : Language -> Tree (ExpressionBlock Expr) -> Accumulator -> ( Accumulator, Tree (ExpressionBlock Expr) )
transformAccumulateTree lang tree acc =
    let
        transformer : Accumulator -> ExpressionBlock Expr -> ( Accumulator, ExpressionBlock Expr )
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
                        updateAccumulator block_ acc_
                in
                ( newAcc, transformBlock lang newAcc block_ )
    in
    Tree.mapAccumulate transformer acc tree


transformBlock : Language -> Accumulator -> ExpressionBlock Expr -> ExpressionBlock Expr
transformBlock lang acc (ExpressionBlock block) =
    case block.blockType of
        OrdinaryBlock [ "section", level ] ->
            let
                title =
                    case block.content of
                        Left str ->
                            str

                        Right expr ->
                            List.map Compiler.ASTTools.getText expr |> Maybe.Extra.values |> String.join " "
            in
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


expand : Dict String Lambda -> ExpressionBlock Expr -> ExpressionBlock Expr
expand dict (ExpressionBlock block) =
    ExpressionBlock { block | content = Either.map (List.map (Lambda.expand dict)) block.content }


updateAccumulator : ExpressionBlock Expr -> Accumulator -> Accumulator
updateAccumulator ((ExpressionBlock { name, args, blockType, content, tag, id }) as block) accumulator =
    let
        updateReference : String -> String -> String -> Accumulator -> Accumulator
        updateReference tag_ id_ numRef_ acc =
            if tag_ /= "" then
                { acc | reference = Dict.insert tag_ { id = id_, numRef = numRef_ } acc.reference }

            else
                acc

        ( inList, initialNumberedCounter ) =
            case ( accumulator.inList, name ) of
                ( False, Just "numbered" ) ->
                    ( True, Just 1 )

                ( False, _ ) ->
                    ( False, Nothing )

                ( True, Just "numbered" ) ->
                    ( True, Nothing )

                ( True, _ ) ->
                    ( False, Nothing )
    in
    case blockType of
        -- provide numbering for sections
        OrdinaryBlock [ "section", level ] ->
            let
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

        OrdinaryBlock args_ ->
            let
                newTag =
                    if name == Just "bibitem" then
                        List.Extra.getAt 0 args

                    else
                        Nothing
            in
            case List.head args_ of
                Just "defs" ->
                    -- incorporate runtime macro definitions
                    case content of
                        Left _ ->
                            accumulator

                        Right exprs ->
                            { accumulator | inList = inList, environment = List.foldl (\lambda dict -> Lambda.insert (Lambda.extract lambda) dict) accumulator.environment exprs }

                Just "numbered" ->
                    let
                        newCounter =
                            case initialNumberedCounter of
                                Nothing ->
                                    incrementCounter "numbered" accumulator.counter

                                Just _ ->
                                    Dict.insert "numbered" 1 accumulator.counter
                    in
                    { accumulator | inList = inList, counter = newCounter }
                        |> updateReference tag id (String.fromInt (getCounter "numbered" newCounter))

                Just name_ ->
                    let
                        revisedTag =
                            if name == Just "bibitem" then
                                List.Extra.getAt 0 args |> Maybe.withDefault ""

                            else
                                tag

                        -- TODO: restrict to name_ in designated (but dynamic) list
                        newCounter =
                            if List.member name_ accumulator.numberedBlockNames then
                                incrementCounter name_ accumulator.counter

                            else
                                accumulator.counter
                    in
                    { accumulator
                        | inList = inList
                        , counter = newCounter
                        , terms = addTermsFromContent id content accumulator.terms
                    }
                        |> updateReference revisedTag id (String.fromInt (getCounter name_ newCounter))

                _ ->
                    { accumulator | inList = inList }

        -- provide for numbering of equations
        VerbatimBlock [ name_ ] ->
            let
                newCounter =
                    if List.member name_ accumulator.numberedBlockNames then
                        incrementCounter name_ accumulator.counter

                    else
                        accumulator.counter
            in
            { accumulator | inList = inList, counter = newCounter }
                |> updateReference tag id (getCounter name_ newCounter |> String.fromInt)

        Paragraph ->
            { accumulator | inList = inList, terms = addTermsFromContent id content accumulator.terms }

        _ ->
            -- TODO: take care of numberedItemIndex
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
        Left str ->
            []



-- TERMS: [Expr "term" [Text "group" { begin = 19, end = 23, index = 4 }] { begin = 13, end = 13, index = 1 }]


extract : String -> Expr -> Maybe TermData
extract id expr =
    case expr of
        Expr "term" [ Text name { begin, end, index } ] _ ->
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
