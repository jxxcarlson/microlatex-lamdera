module Evergreen.V102.Compiler.DifferentialParser exposing (..)

import Evergreen.V102.Compiler.AbstractDifferentialParser
import Evergreen.V102.Compiler.Acc
import Evergreen.V102.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V102.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V102.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V102.Parser.Block.ExpressionBlock) Evergreen.V102.Compiler.Acc.Accumulator
