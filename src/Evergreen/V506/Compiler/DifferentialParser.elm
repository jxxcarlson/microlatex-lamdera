module Evergreen.V506.Compiler.DifferentialParser exposing (..)

import Evergreen.V506.Compiler.AbstractDifferentialParser
import Evergreen.V506.Compiler.Acc
import Evergreen.V506.Parser.Block
import Evergreen.V506.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V506.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V506.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V506.Parser.Block.ExpressionBlock) Evergreen.V506.Compiler.Acc.Accumulator
