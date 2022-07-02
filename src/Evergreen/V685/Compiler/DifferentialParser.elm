module Evergreen.V685.Compiler.DifferentialParser exposing (..)

import Evergreen.V685.Compiler.AbstractDifferentialParser
import Evergreen.V685.Compiler.Acc
import Evergreen.V685.Parser.Block
import Evergreen.V685.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V685.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V685.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V685.Parser.Block.ExpressionBlock) Evergreen.V685.Compiler.Acc.Accumulator
