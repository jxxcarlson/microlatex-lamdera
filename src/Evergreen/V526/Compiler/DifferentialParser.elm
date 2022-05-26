module Evergreen.V526.Compiler.DifferentialParser exposing (..)

import Evergreen.V526.Compiler.AbstractDifferentialParser
import Evergreen.V526.Compiler.Acc
import Evergreen.V526.Parser.Block
import Evergreen.V526.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V526.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V526.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V526.Parser.Block.ExpressionBlock) Evergreen.V526.Compiler.Acc.Accumulator
