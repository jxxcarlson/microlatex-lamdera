module Evergreen.V675.Compiler.DifferentialParser exposing (..)

import Evergreen.V675.Compiler.AbstractDifferentialParser
import Evergreen.V675.Compiler.Acc
import Evergreen.V675.Parser.Block
import Evergreen.V675.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V675.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V675.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V675.Parser.Block.ExpressionBlock) Evergreen.V675.Compiler.Acc.Accumulator
