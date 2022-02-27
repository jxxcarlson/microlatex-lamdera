module Evergreen.V12.Compiler.DifferentialParser exposing (..)

import Evergreen.V12.Compiler.AbstractDifferentialParser
import Evergreen.V12.Compiler.Acc
import Evergreen.V12.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V12.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V12.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V12.Parser.Block.ExpressionBlock) Evergreen.V12.Compiler.Acc.Accumulator
