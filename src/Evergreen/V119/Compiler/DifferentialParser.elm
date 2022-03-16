module Evergreen.V119.Compiler.DifferentialParser exposing (..)

import Evergreen.V119.Compiler.AbstractDifferentialParser
import Evergreen.V119.Compiler.Acc
import Evergreen.V119.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V119.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V119.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V119.Parser.Block.ExpressionBlock) Evergreen.V119.Compiler.Acc.Accumulator
