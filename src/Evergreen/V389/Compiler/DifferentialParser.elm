module Evergreen.V389.Compiler.DifferentialParser exposing (..)

import Evergreen.V389.Compiler.AbstractDifferentialParser
import Evergreen.V389.Compiler.Acc
import Evergreen.V389.Parser.Block
import Evergreen.V389.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V389.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V389.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V389.Parser.Block.ExpressionBlock) Evergreen.V389.Compiler.Acc.Accumulator
