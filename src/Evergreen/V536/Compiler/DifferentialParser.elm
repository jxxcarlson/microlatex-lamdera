module Evergreen.V536.Compiler.DifferentialParser exposing (..)

import Evergreen.V536.Compiler.AbstractDifferentialParser
import Evergreen.V536.Compiler.Acc
import Evergreen.V536.Parser.Block
import Evergreen.V536.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V536.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V536.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V536.Parser.Block.ExpressionBlock) Evergreen.V536.Compiler.Acc.Accumulator
