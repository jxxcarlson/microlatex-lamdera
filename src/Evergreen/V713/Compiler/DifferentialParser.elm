module Evergreen.V713.Compiler.DifferentialParser exposing (..)

import Evergreen.V713.Compiler.AbstractDifferentialParser
import Evergreen.V713.Compiler.Acc
import Evergreen.V713.Parser.Block
import Evergreen.V713.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V713.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V713.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V713.Parser.Block.ExpressionBlock) Evergreen.V713.Compiler.Acc.Accumulator
