module Evergreen.V82.Compiler.DifferentialParser exposing (..)

import Evergreen.V82.Compiler.AbstractDifferentialParser
import Evergreen.V82.Compiler.Acc
import Evergreen.V82.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V82.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V82.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V82.Parser.Block.ExpressionBlock) Evergreen.V82.Compiler.Acc.Accumulator
