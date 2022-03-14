module Evergreen.V88.Compiler.DifferentialParser exposing (..)

import Evergreen.V88.Compiler.AbstractDifferentialParser
import Evergreen.V88.Compiler.Acc
import Evergreen.V88.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V88.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V88.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V88.Parser.Block.ExpressionBlock) Evergreen.V88.Compiler.Acc.Accumulator
