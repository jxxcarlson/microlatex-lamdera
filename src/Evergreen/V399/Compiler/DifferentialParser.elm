module Evergreen.V399.Compiler.DifferentialParser exposing (..)

import Evergreen.V399.Compiler.AbstractDifferentialParser
import Evergreen.V399.Compiler.Acc
import Evergreen.V399.Parser.Block
import Evergreen.V399.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V399.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V399.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V399.Parser.Block.ExpressionBlock) Evergreen.V399.Compiler.Acc.Accumulator
