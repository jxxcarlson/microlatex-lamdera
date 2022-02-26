module Evergreen.V7.Compiler.DifferentialParser exposing (..)

import Evergreen.V7.Compiler.AbstractDifferentialParser
import Evergreen.V7.Compiler.Acc
import Evergreen.V7.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V7.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V7.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V7.Parser.Block.ExpressionBlock) Evergreen.V7.Compiler.Acc.Accumulator
