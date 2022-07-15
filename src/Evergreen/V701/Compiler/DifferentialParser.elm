module Evergreen.V701.Compiler.DifferentialParser exposing (..)

import Evergreen.V701.Compiler.AbstractDifferentialParser
import Evergreen.V701.Compiler.Acc
import Evergreen.V701.Parser.Block
import Evergreen.V701.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V701.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V701.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V701.Parser.Block.ExpressionBlock) Evergreen.V701.Compiler.Acc.Accumulator
