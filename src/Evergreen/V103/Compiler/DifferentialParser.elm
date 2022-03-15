module Evergreen.V103.Compiler.DifferentialParser exposing (..)

import Evergreen.V103.Compiler.AbstractDifferentialParser
import Evergreen.V103.Compiler.Acc
import Evergreen.V103.Parser.Block
import Tree


type alias EditRecord =
    Evergreen.V103.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V103.Parser.Block.IntermediateBlock) (Tree.Tree Evergreen.V103.Parser.Block.ExpressionBlock) Evergreen.V103.Compiler.Acc.Accumulator
