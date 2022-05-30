module Evergreen.V533.Compiler.DifferentialParser exposing (..)

import Evergreen.V533.Compiler.AbstractDifferentialParser
import Evergreen.V533.Compiler.Acc
import Evergreen.V533.Parser.Block
import Evergreen.V533.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V533.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V533.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V533.Parser.Block.ExpressionBlock) Evergreen.V533.Compiler.Acc.Accumulator
