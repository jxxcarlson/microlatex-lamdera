module Evergreen.V674.Compiler.DifferentialParser exposing (..)

import Evergreen.V674.Compiler.AbstractDifferentialParser
import Evergreen.V674.Compiler.Acc
import Evergreen.V674.Parser.Block
import Evergreen.V674.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V674.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V674.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V674.Parser.Block.ExpressionBlock) Evergreen.V674.Compiler.Acc.Accumulator
