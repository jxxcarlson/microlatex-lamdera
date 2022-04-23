module Evergreen.V477.Compiler.DifferentialParser exposing (..)

import Evergreen.V477.Compiler.AbstractDifferentialParser
import Evergreen.V477.Compiler.Acc
import Evergreen.V477.Parser.Block
import Evergreen.V477.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V477.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V477.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V477.Parser.Block.ExpressionBlock) Evergreen.V477.Compiler.Acc.Accumulator
