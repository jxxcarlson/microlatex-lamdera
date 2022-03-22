module Evergreen.V148.Compiler.DifferentialParser exposing (..)

import Evergreen.V148.Compiler.AbstractDifferentialParser
import Evergreen.V148.Compiler.Acc
import Evergreen.V148.Parser.Block
import Evergreen.V148.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V148.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V148.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V148.Parser.Block.ExpressionBlock) Evergreen.V148.Compiler.Acc.Accumulator
