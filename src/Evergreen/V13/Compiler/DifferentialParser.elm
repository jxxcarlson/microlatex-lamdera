module Evergreen.V13.Compiler.DifferentialParser exposing (..)

import Evergreen.V13.Compiler.AbstractDifferentialParser
import Evergreen.V13.Compiler.Acc
import Evergreen.V13.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V13.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V13.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V13.Parser.Block.ExpressionBlock) Evergreen.V13.Compiler.Acc.Accumulator
