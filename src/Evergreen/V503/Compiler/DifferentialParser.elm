module Evergreen.V503.Compiler.DifferentialParser exposing (..)

import Evergreen.V503.Compiler.AbstractDifferentialParser
import Evergreen.V503.Compiler.Acc
import Evergreen.V503.Parser.Block
import Evergreen.V503.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V503.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V503.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V503.Parser.Block.ExpressionBlock) Evergreen.V503.Compiler.Acc.Accumulator
