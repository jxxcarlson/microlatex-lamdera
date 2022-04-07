module Evergreen.V279.Compiler.DifferentialParser exposing (..)

import Evergreen.V279.Compiler.AbstractDifferentialParser
import Evergreen.V279.Compiler.Acc
import Evergreen.V279.Parser.Block
import Evergreen.V279.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V279.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V279.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V279.Parser.Block.ExpressionBlock) Evergreen.V279.Compiler.Acc.Accumulator
