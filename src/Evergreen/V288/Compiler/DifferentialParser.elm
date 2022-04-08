module Evergreen.V288.Compiler.DifferentialParser exposing (..)

import Evergreen.V288.Compiler.AbstractDifferentialParser
import Evergreen.V288.Compiler.Acc
import Evergreen.V288.Parser.Block
import Evergreen.V288.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V288.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V288.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V288.Parser.Block.ExpressionBlock) Evergreen.V288.Compiler.Acc.Accumulator
