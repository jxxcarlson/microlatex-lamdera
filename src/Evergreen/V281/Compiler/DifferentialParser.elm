module Evergreen.V281.Compiler.DifferentialParser exposing (..)

import Evergreen.V281.Compiler.AbstractDifferentialParser
import Evergreen.V281.Compiler.Acc
import Evergreen.V281.Parser.Block
import Evergreen.V281.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V281.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V281.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V281.Parser.Block.ExpressionBlock) Evergreen.V281.Compiler.Acc.Accumulator
