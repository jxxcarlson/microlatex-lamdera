module Evergreen.V557.Compiler.DifferentialParser exposing (..)

import Evergreen.V557.Compiler.AbstractDifferentialParser
import Evergreen.V557.Compiler.Acc
import Evergreen.V557.Parser.Block
import Evergreen.V557.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V557.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V557.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V557.Parser.Block.ExpressionBlock) Evergreen.V557.Compiler.Acc.Accumulator
