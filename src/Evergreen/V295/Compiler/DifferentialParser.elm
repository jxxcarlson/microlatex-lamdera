module Evergreen.V295.Compiler.DifferentialParser exposing (..)

import Evergreen.V295.Compiler.AbstractDifferentialParser
import Evergreen.V295.Compiler.Acc
import Evergreen.V295.Parser.Block
import Evergreen.V295.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V295.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V295.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V295.Parser.Block.ExpressionBlock) Evergreen.V295.Compiler.Acc.Accumulator
