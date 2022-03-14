module Evergreen.V91.Compiler.DifferentialParser exposing (..)

import Evergreen.V91.Compiler.AbstractDifferentialParser
import Evergreen.V91.Compiler.Acc
import Evergreen.V91.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V91.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V91.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V91.Parser.Block.ExpressionBlock) Evergreen.V91.Compiler.Acc.Accumulator
