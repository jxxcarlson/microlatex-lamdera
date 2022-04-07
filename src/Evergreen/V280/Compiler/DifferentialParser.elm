module Evergreen.V280.Compiler.DifferentialParser exposing (..)

import Evergreen.V280.Compiler.AbstractDifferentialParser
import Evergreen.V280.Compiler.Acc
import Evergreen.V280.Parser.Block
import Evergreen.V280.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V280.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V280.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V280.Parser.Block.ExpressionBlock) Evergreen.V280.Compiler.Acc.Accumulator
