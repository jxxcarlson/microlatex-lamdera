module Evergreen.V92.Compiler.DifferentialParser exposing (..)

import Evergreen.V92.Compiler.AbstractDifferentialParser
import Evergreen.V92.Compiler.Acc
import Evergreen.V92.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V92.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V92.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V92.Parser.Block.ExpressionBlock) Evergreen.V92.Compiler.Acc.Accumulator
