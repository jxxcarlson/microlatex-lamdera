module Compiler.Acc exposing
    ( Accumulator
    , init
    , make
    , transformST
    )

import Compiler.Lambda as Lambda exposing (Lambda)
import Compiler.Vector as Vector exposing (Vector)
import Dict exposing (Dict)
import Either exposing (Either(..))
import L0.Transform
import List.Extra
import MicroLaTeX.Compiler.LaTeX
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr)
import Parser.Language exposing (Language(..))
import Tree exposing (Tree)


type alias Accumulator =
    { headingIndex : Vector
    , counter : Dict String Int
    , environment : Dict String Lambda
    , inList : Bool
    , reference : Dict String { id : String, numRef : String }
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
    , environment = Dict.empty
    , reference = Dict.empty
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
                                L0.Transform.transform block__ |> Debug.log "TRANSFORMED"

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
            { acc | reference = Dict.insert tag_ { id = id_, numRef = numRef_ } acc.reference }

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
                headingIndex =
                    Vector.increment (String.toInt level |> Maybe.withDefault 0 |> (\x -> x - 1)) accumulator.headingIndex
            in
            -- TODO: take care of numberedItemIndex = 0 here and elsewhere
            { accumulator | inList = inList, headingIndex = headingIndex } |> updateReference tag id (Vector.toString headingIndex)

        OrdinaryBlock args_ ->
            case List.head args_ of
                Just "defs" ->
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
                        -- TODO: restrict to name_ in designated (but dynamic) list
                        newCounter =
                            incrementCounter name_ accumulator.counter
                    in
                    { accumulator | inList = inList, counter = newCounter }
                        |> updateReference tag id (String.fromInt (getCounter name_ newCounter))

                _ ->
                    { accumulator | inList = inList }

        -- provide for numbering of equations
        VerbatimBlock [ name_ ] ->
            let
                newCounter =
                    incrementCounter name_ accumulator.counter
            in
            { accumulator | inList = inList, counter = newCounter } |> updateReference tag id (getCounter name_ newCounter |> String.fromInt)

        _ ->
            -- TODO: take care of numberedItemIndex
            { accumulator | inList = inList }
