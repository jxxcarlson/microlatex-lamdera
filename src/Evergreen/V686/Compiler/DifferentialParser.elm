module Evergreen.V686.Compiler.DifferentialParser exposing (..)

import Evergreen.V686.Compiler.AbstractDifferentialParser
import Evergreen.V686.Compiler.Acc
import Evergreen.V686.Parser.Block
import Evergreen.V686.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V686.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V686.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V686.Parser.Block.ExpressionBlock) Evergreen.V686.Compiler.Acc.Accumulator
