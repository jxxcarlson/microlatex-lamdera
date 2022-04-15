module Evergreen.V369.Compiler.DifferentialParser exposing (..)

import Evergreen.V369.Compiler.AbstractDifferentialParser
import Evergreen.V369.Compiler.Acc
import Evergreen.V369.Parser.Block
import Evergreen.V369.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V369.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V369.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V369.Parser.Block.ExpressionBlock) Evergreen.V369.Compiler.Acc.Accumulator
