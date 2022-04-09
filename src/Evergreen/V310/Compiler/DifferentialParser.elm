module Evergreen.V310.Compiler.DifferentialParser exposing (..)

import Evergreen.V310.Compiler.AbstractDifferentialParser
import Evergreen.V310.Compiler.Acc
import Evergreen.V310.Parser.Block
import Evergreen.V310.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V310.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V310.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V310.Parser.Block.ExpressionBlock) Evergreen.V310.Compiler.Acc.Accumulator
