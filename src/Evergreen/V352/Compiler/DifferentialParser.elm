module Evergreen.V352.Compiler.DifferentialParser exposing (..)

import Evergreen.V352.Compiler.AbstractDifferentialParser
import Evergreen.V352.Compiler.Acc
import Evergreen.V352.Parser.Block
import Evergreen.V352.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V352.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V352.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V352.Parser.Block.ExpressionBlock) Evergreen.V352.Compiler.Acc.Accumulator
