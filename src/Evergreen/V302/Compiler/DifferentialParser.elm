module Evergreen.V302.Compiler.DifferentialParser exposing (..)

import Evergreen.V302.Compiler.AbstractDifferentialParser
import Evergreen.V302.Compiler.Acc
import Evergreen.V302.Parser.Block
import Evergreen.V302.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V302.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V302.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V302.Parser.Block.ExpressionBlock) Evergreen.V302.Compiler.Acc.Accumulator
