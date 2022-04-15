module Evergreen.V378.Compiler.DifferentialParser exposing (..)

import Evergreen.V378.Compiler.AbstractDifferentialParser
import Evergreen.V378.Compiler.Acc
import Evergreen.V378.Parser.Block
import Evergreen.V378.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V378.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V378.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V378.Parser.Block.ExpressionBlock) Evergreen.V378.Compiler.Acc.Accumulator
