module Evergreen.V194.Compiler.DifferentialParser exposing (..)

import Evergreen.V194.Compiler.AbstractDifferentialParser
import Evergreen.V194.Compiler.Acc
import Evergreen.V194.Parser.Block
import Evergreen.V194.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V194.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V194.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V194.Parser.Block.ExpressionBlock) Evergreen.V194.Compiler.Acc.Accumulator
