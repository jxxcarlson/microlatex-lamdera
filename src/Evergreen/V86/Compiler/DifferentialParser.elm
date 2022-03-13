module Evergreen.V86.Compiler.DifferentialParser exposing (..)

import Evergreen.V86.Compiler.AbstractDifferentialParser
import Evergreen.V86.Compiler.Acc
import Evergreen.V86.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V86.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V86.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V86.Parser.Block.ExpressionBlock) Evergreen.V86.Compiler.Acc.Accumulator
