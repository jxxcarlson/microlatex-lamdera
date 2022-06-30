module Evergreen.V679.Compiler.DifferentialParser exposing (..)

import Evergreen.V679.Compiler.AbstractDifferentialParser
import Evergreen.V679.Compiler.Acc
import Evergreen.V679.Parser.Block
import Evergreen.V679.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V679.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V679.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V679.Parser.Block.ExpressionBlock) Evergreen.V679.Compiler.Acc.Accumulator
