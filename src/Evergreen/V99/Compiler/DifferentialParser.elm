module Evergreen.V99.Compiler.DifferentialParser exposing (..)

import Evergreen.V99.Compiler.AbstractDifferentialParser
import Evergreen.V99.Compiler.Acc
import Evergreen.V99.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V99.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V99.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V99.Parser.Block.ExpressionBlock) Evergreen.V99.Compiler.Acc.Accumulator
