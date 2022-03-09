module MicroLaTeX.Parser.Classify exposing (Classification, classify)

import Compiler.Util
import List.Extra
import Parser.Block exposing (BlockType(..))
import Parser.Common
import Parser.PrimitiveBlock exposing (PrimitiveBlock)


type alias Classification =
    { blockType : BlockType, args : List String, name : Maybe String }


classify : PrimitiveBlock -> Classification
classify block =
   case block.name of 
       "item" -> 
        { blockType = OrdinaryBlock [ "item" ], args = [], name = Just "item" }

       "index" -> 
        { blockType = OrdinaryBlock [ "index" ], args = [], name = Just "index" }

       "abstract" ->
        { blockType = OrdinaryBlock [ "abstract" ], args = [], name = Just "abstract" }

        "numbered" ->
        { blockType = OrdinaryBlock [ "numbered" ], args = [], name = Just "numbered" }

       "desc" ->
        { blockType = OrdinaryBlock [ "desc" ], args = block.args, name = Just "desc" }

       Just name_  ->
                if List.member name_ Parser.Common.verbatimBlockNames ->
                     { blockType = VerbatimBlock [ block.name ], args = block.args, name = Just name }
                else
                     {blockType = OrdinaryBlock [ block.name ], args = block.args, name = Just name }

       Nothing ->
           (case List.Extra.getAt 1 block.content of

               Just "$$" ->
                   { blockType = VerbatimBlock [ "math" ], args = [], name = Just "math" }
               Just "```" ->
                   { blockType = VerbatimBlock [ "code" ], args = [], name = Just "code" }

               _ -> {blockType = Paragraph, args = [],  name = block.name }) |> Debug.log "BT, X"


