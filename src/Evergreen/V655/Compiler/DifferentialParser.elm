module Evergreen.V655.Compiler.DifferentialParser exposing (..)

import Evergreen.V655.Compiler.AbstractDifferentialParser
import Evergreen.V655.Compiler.Acc
import Evergreen.V655.Parser.Block
import Evergreen.V655.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V655.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V655.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V655.Parser.Block.ExpressionBlock) Evergreen.V655.Compiler.Acc.Accumulator
